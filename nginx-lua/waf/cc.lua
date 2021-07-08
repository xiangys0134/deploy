--[[
 	
						 CC_S_IP_BLACKLIST
 							/----\				  /----\					 /-----------\
	|--------|    【读】    /	  \	    【否】    /      \ 【写CC_IS_ATTACK】 /             \    【否】    |-----------|
|-> | 普通请求|	-------->  | 黑明单|  ---------> ｜ 高并发｜----------------->| CC_IS_ATTACK |-----------> |正常业务访问|
|   |--------| 			   \	  /              \      /					\			  /			     |----------|
|                  			\----/                \----/					 \-----------/												   CC_S_WHITELIST
|					           |													| 										/----\ 			   /----\				  
|							   |													| 【是】        |--------|   【读】      /      \   【否】   /      \ 		【是】	  |-----------|
| 							   |	     CC_S_IP_BLACKLIST           				|------------> | 判黑处理	| -----------> | 黑明单｜--------> | 白明单｜-------------> | 正常业务访问|
| 							   | 【是】       /----\              / -------\ 					   |--------|			   \      /    【读】  \      / 				  |-----------|	
|	|--------|	  【读】		   | 	        /      \   【否】    / 		   \   【成功】				    | 					\----/			   \----/
|	| 滑块请求|	-------------^^|^^--------->| 黑名单｜--------->	| auth-check|-----------			    |					   |                  |
|	|--------|				   |            \      /            \           /          |				|【是】				   |				  |	
|		^					   |	         \----/    			 \---------/		   |				|					   |                  |
|		|					   |                |					  |				   |				|					   |				  |	
|		|	     |----|		   |	            | 【是】               |                |				V					   |	     		  |	
|	    |--------| 555| <------|             	|                     |【失败】         |			|---------------|	           |【是】			  |【否】	
|			     |----| <----------------------- 					  | 			   |        | 写黑明单，清记录｜     		   |				  |
|					^												  V				   |		| 从白名单移除    |			   |				  |	
|					|											 ｜-------｜			   |		|---------------|			   |				  |
|					| ------------------------------------------ ｜写黑明单｜            |									   |				  |
|					| -----------------------------------------| ｜-------｜	           |   									   |				  |
|															   |---------------------^^|^^-------------------------------------|-------------------	
|				 |----|				  【写白明单，从黑明单中移除】  					   |	
|--------------- | 556|	<--------------------------------------------------------------|  															
				 |----|					CC_S_IP_WHITELIST


]]



----------------------------------常量配置----------------------------
--redis配置
local REDIS_ADDR = "127.0.0.1"
local REDIS_PORT = 6379
local REDIS_PASSWORD = "yZOUAOehgRpjUeJI"
local REDIS_TIMEOUT = 20000 -- ms

--redis key 
local CC_L_IP_RECORDLIST = "CC_L_IP_RECORDLIST"
local CC_S_IP_BLACKLIST = "CC_S_IP_BLACKLIST"
local CC_S_IP_WHITELIST = "CC_S_IP_WHITELIST"
local CC_ATTACK_COUNT = "CC_ATTACK_COUNT"

-- redis ttl
local CC_L_IP_RECORDLIST_TTL = 60 * 60 * 24 -- s
local CC_L_IP_RECORD_TTL = 60 * 60 -- s
local CC_IS_ATTACK_TTL = 60 * 60 -- s

-- status
local NGINX_BLOCK_IP_BLACK  = 555
local NGINX_AUTH_SUCCESS = 556


--判异常环境，当每ABNORMAL_ENV_REQUEST_TIME毫秒的请求数大于ABNORMAL_ENV_REQUEST_COUNT就判异常
local ABNORMAL_ENV_REQUEST_TIME = 60000 -- ms
local ABNORMAL_ENV_REQUEST_COUNT = 500 -- 次数

-- 同一个IP，同一URL两次请求的间隔
local SAME_IP_SAME_URL_REQUEST_INTERNAL = 200 -- ms

--鉴黑规则
local RULE_COUNT = {3,   3,     15,    18,     20   } -- count
local RULE_TIME = {1000, 10000, 30000, 45000, 60000} -- ms


----------------------------------函数-------------------------------
-- 获取客户端的IP
local function getClientIp()
	local headers=ngx.req.get_headers()
    local clientIp = "0.0.0.0"

    --TODO 是否需要对客服端IP进行正则匹配

    local x_real_ip = headers["X-REAL-IP"]
    if x_real_ip then
        clientIp = x_real_ip
    end

    local x_forwarded_for_ip = headers["X_FORWARDED_FOR"]
    if x_forwarded_for_ip then
        clientIp = x_forwarded_for_ip
    end

    local remote_addr_ip = ngx.var.remote_addr
    if remote_addr_ip then
        clientIp = remote_addr_ip
    end

    return clientIp
end

-- 判断IP是否在白名单里
local function isWhiteIp(rdsCache, ip)
    local res, err = rdsCache:sismember(CC_S_IP_WHITELIST, ip)
    if res == 0 then
        --没有该key, 或该元素不存在
        return false
    elseif res == 1 then
        -- 存在于白名单列表 
		return true
    end
end

-- 判断IP是否在黑名单里
local function isBlackIp(rdsCache, ip)
    local res, err = rdsCache:sismember(CC_S_IP_BLACKLIST, ip)
    if res == 0 then
        --没有该key, 或该元素不存在
        return false
    elseif res == 1 then
        -- 存在于黑名单列表 该IP被禁
		return true
    end
end

-- nginx exit
local function ngxBlock(rdsCache, retCode)
	--close redis connect
	local is_close, err = rdsCache:close()
	ngx.status = retCode
	ngx.exit(retCode)
end

--判黑处理器
local function ipBlackHandler(rdsCache, ip, uri, ip_url_key)
	-- 添加至访问黑名单，清除当前判定为黑名单的key，从白名单移除
     rdsCache:sadd(CC_S_IP_BLACKLIST, ip)
     rdsCache:del(ip_url_key)
     rdsCache:srem(CC_S_IP_WHITELIST, ip)

     -- 记录当前被判黑的uri
	local black_ip_uri = "BLOCK" .. "_" .. ip;
     rdsCache:set(black_ip_uri, uri)

     -- 返回555的status
     ngxBlock(rdsCache, NGINX_BLOCK_IP_BLACK)
end

-- 单个IP鉴黑判断
local function judgeIpBlockCheck(rdsCache, ip, host, uri)

     local url = host..uri
    	local ip_url_key = ip .. "." .. ngx.md5(url)
	
	local current_time = ngx.now()

	--连接成功，插入一条请求记录，存于redis.list中
	local lenRes, err = rdsCache:llen(ip_url_key)
     if not lenRes or lenRes == 0 then
		--没有该key，新入一条，并设置TTL
		rdsCache:lpush(ip_url_key, current_time)
          rdsCache:expire(ip_url_key, CC_L_IP_RECORD_TTL)
		lenRes = 1
     else
		rdsCache:lpush(ip_url_key, current_time)
     end

	-- 同一个IP，同一个URL请求过于频繁，拉黑处理
	local timeRes, err = rdsCache:lrange(ip_url_key,0,1)
	if timeRes then
    	  local firstItem = timeRes[1]
    	  local secondItem = timeRes[2]
       if firstItem and secondItem then
         local request_internal = (firstItem - secondItem) * 1000
         if request_internal <= SAME_IP_SAME_URL_REQUEST_INTERNAL then
         	 rdsCache:set("BLACK_SAME_IP_SAME_URL_REQUEST" .. "_" .. ip_url_key, 1)
		 ipBlackHandler(rdsCache, ip, uri, ip_url_key)
         end
       end
     end

	--单个IP频次鉴黑判断	
	local space_time = 0
	local timeRes, err = rdsCache:lrange(ip_url_key,-1,-1)
	if timeRes then
		space_time = (current_time - timeRes[1])*1000
	end

	local idx = 1
	local lenRes, err = rdsCache:llen(ip_url_key)
	for k, v in pairs(RULE_COUNT) do
		if lenRes >= RULE_COUNT[idx] then
			if space_time <= RULE_TIME[idx] then
				rdsCache:set("BLACK_RULE_COUNT" .. "_" .. ip_url_key .. "_" .. lenRes .. "_" .. idx, 1)
				ipBlackHandler(rdsCache, ip, uri, ip_url_key)
			end
		end
		idx = idx + 1
	end
end

-- 获取当前是否是高并发场景
local function isAttacked(rdsCache )
	local count, err = rdsCache:get(CC_ATTACK_COUNT)
	if tonumber(count) then
		if tonumber(count) > 1 then
			return true
		end
	end
	return false
end

-- 判断是否是高并发场景
local function CheckCurIsAttackEnv(rdsCache)

	-- 判断当前是否是高并发环境
	local is_Attacked, err = isAttacked(rdsCache)
	if is_Attacked then
	    return
	end
	
    local curTime = ngx.now()
    local lenRes, err = rdsCache:llen(CC_L_IP_RECORDLIST)
    if not lenRes or lenRes == 0 then
		--没有该key，新入一条，并设置TTL
		rdsCache:lpush(CC_L_IP_RECORDLIST, curTime)
          rdsCache:expire(CC_L_IP_RECORDLIST, CC_L_IP_RECORDLIST_TTL)
		lenRes = 1
    else
		rdsCache:lpush(CC_L_IP_RECORDLIST, curTime)
	end

	if lenRes >= ABNORMAL_ENV_REQUEST_COUNT then
		--最近ABNORMAL_ENV_REQUEST_COUNT条的之间间隔是否小于ABNORMAL_ENV_REQUEST_TIME
		local space_time = 0
		local timeRes, err = rdsCache:lrange(CC_L_IP_RECORDLIST,ABNORMAL_ENV_REQUEST_COUNT-1,ABNORMAL_ENV_REQUEST_COUNT-1)
		if timeRes then
			space_time = (curTime - timeRes[1])*1000
			if space_time <= ABNORMAL_ENV_REQUEST_TIME then
				rdsCache:incr(CC_ATTACK_COUNT)
				rdsCache:expire(CC_ATTACK_COUNT, CC_IS_ATTACK_TTL)
			end
		end
	end
end

----------------------------------逻辑执行-------------------------------
-- 连接redis
local redis = require "resty.redis"
local rdsCache = redis:new()
local is_connected_succes, err = rdsCache:connect(REDIS_ADDR, REDIS_PORT)
rdsCache:auth(REDIS_PASSWORD)
rdsCache:set_timeout(REDIS_TIMEOUT)

if not is_connected_succes then
    --连接失败，close
	ngx.log(ngx.ERR, " >>>cc.lua redis连接失败")
    local ok, err = rdsCache:close()
end

if is_connected_succes then

	-- 判断是否是黑名单
	local clientIp = getClientIp()
	local isBlack = isBlackIp(rdsCache, clientIp)
	if isBlack then
		ngx.log(ngx.ERR, "-----[cc.lua] 第一次黑名单判黑导致滑块验证----- ")
		ngxBlock(rdsCache, NGINX_BLOCK_IP_BLACK)
	end	

	-- 高并发环境检测
	CheckCurIsAttackEnv(rdsCache)

	-- 判断当前是否是高并发环境
	local is_Attacked, err = isAttacked(rdsCache)
	if is_Attacked then
		-- 当前是高并发场景

		-- 判黑处理
		local uri = ngx.var.request_uri
     	local host = ngx.var.host
		judgeIpBlockCheck(rdsCache, clientIp, host, uri) 
	
		local isBlack_2 = isBlackIp(rdsCache, clientIp)
			if isBlack_2 then
				-- 是黑名单
				ngx.log(ngx.ERR, " -----[cc.lua] 攻击        location /_nuxt/ {
              proxy_set_header    X-Real-IP                    $remote_addr;
              proxy_set_header    X-Forwarded-For              $proxy_add_x_forwarded_for;
              proxy_set_header    HTTP_X_FORWARDED_FOR      $remote_addr;
              proxy_pass http://www;
        }

        location /api/ {
               proxy_set_header    X-Real-IP                    $remote_addr;
               proxy_set_header    X-Forwarded-For              $proxy_add_x_forwarded_for;
               proxy_set_header    HTTP_X_FORWARDED_FOR      $remote_addr;
               proxy_pass http://www;
        }

        location /nprod/ {
                proxy_set_header    X-Real-IP                    $remote_addr;
                proxy_set_header    X-Forwarded-For              $proxy_add_x_forwarded_for;
                proxy_set_header    HTTP_X_FORWARDED_FOR      $remote_addr;
                proxy_pass http://www;
         }

        location /stage/ {
               proxy_set_header    X-Real-IP                    $remote_addr;
               proxy_set_header    X-Forwarded-For              $proxy_add_x_forwarded_for;
               proxy_set_header    HTTP_X_FORWARDED_FOR      $remote_addr;
               proxy_pass http://www;
        } ")
				ngxBlock(rdsCache, NGINX_BLOCK_IP_BLACK)
			else
				local isWhite = isWhiteIp(rdsCache, clientIp)
				if isWhite then
					local is_close, err = rdsCache:close()
    					return
		    		else
		    			ngx.log(ngx.ERR, " -----[cc.lua] 攻击场景下非白名单导致滑块验证----- ")
		    			 -- 记录当前被阻塞的uri
					local black_ip_uri = "BLOCK" .. "_" .. clientIp;
    					rdsCache:set(black_ip_uri, uri)
		    			ngxBlock(rdsCache, NGINX_BLOCK_IP_BLACK)
		    		end		
			end	
	else
		-- 当前不是高并发场景
		local is_close, err = rdsCache:close()
    		return
	end	
end


