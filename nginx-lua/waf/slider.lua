--[[
 	
						 CC_S_IP_BLACKLIST
 							/----\				  /----\					 /-----------\
	|--------|    【读】    /	  \	    【否】    /      \ 【写CC_IS_ATTACK】 /             \    【否】    |-----------|
|-> | 普通请求|	-------->  | 黑明单|  ---------> ｜ 高并发｜----------------->| CC_IS_ATTACK |-----------> |正常业务访问|
|   |--------| 			   \	  /              \      /					\			  /			     |----------|
|                  			\----/                \----/					 \-----------/												   CC_S_WHITELIST
|					           |													| 										/----\ 			   /----\				  
|							   |													| 【是】        |--------|   【读】      /      \   【否】   /      \ 		【是】	  |-----------|
| 							   |	CC_S_IP_SLIDER_BLACKLIST           				|------------> | 判黑处理	| -----------> | 黑明单｜--------> | 白明单｜-------------> | 正常业务访问|
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
local CC_S_IP_SLIDER_BLACKLIST = "CC_S_IP_SLIDER_BLACKLIST"
local CC_S_IP_BLACKLIST = "CC_S_IP_BLACKLIST"
local CC_S_IP_WHITELIST = "CC_S_IP_WHITELIST"
local CC_TOKEN_PREFIX = "TOKEN."

-- redis ttl
local REDIS_TOKEN_TTL = 60 *30 -- ms

-- status
local NGINX_BLOCK_IP_BLACK  = 555
local NGINX_AUTH_SUCCESS = 556



-- 鉴权时随机常量字符表
local CHAR_BOARD_LIST = { "E", "p", "B", "y", "m", "6", "n", "v", "U", "s", "8", "l", "Y", "x", "C", "q", "7", "b", "W", "i", "N",
                     "2", "u", "o", "V", "g", "D", "9", "a", "G", "A", "1", "I", "M", "d", "0", "z", "k", "X", "t", "S", "f",
                     "5", "J", "c", "Z", "O", "r", "H", "w", "P", "3", "F", "R", "L", "T", "e", "4", "Q", "h", "K", "j" }

-- 前后端约定的常量密钥
local AUTH_SECRET = "Fazzaco@123.test"

-- 滑块请求携带的请求头
local TIME_STAMP_HEADER = "TS"
local RANDOM_NUM_HEADER = "RD"
local TOKEN = "TK"


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

-- 判断IP是否在黑名单里
local function isBlackIp(rdsCache, ip)
    local res, err = rdsCache:sismember(CC_S_IP_SLIDER_BLACKLIST, ip)
    if res == 0 then
        --没有该key, 或该元素不存在
        return false
    elseif res == 1 then
        -- 存在于黑名单列表 该IP被禁
		return false
    end
end

-- nginx exit
local function ngxBlock(rdsCache, retCode)
	ngx.status = retCode
	if retCode == NGINX_AUTH_SUCCESS then 
	  local clientIp = getClientIp()
	  local black_ip_uri = "BLOCK" .. "_" .. clientIp;
       local black_uri = rdsCache:get(black_ip_uri)
       rdsCache:del(black_ip_uri)
       ngx.say(black_uri)	
	end
	ngx.exit(retCode)

	--close redis connect
	local is_close, err = rdsCache:close()
end

-- 根据随机数与char_board_list的长度取余的结果，获取char_board_list中对应的字符
-- 将随机字符插入str对应的位置
local function insert_char_Str(str, number, char_board_list)
    local str_index = number % string.len(str)
    local char_board_list_index = number % #char_board_list
    local num_to_char = char_board_list[char_board_list_index + 1]
    local converted_md5 = string.sub(str, 0, str_index) .. num_to_char .. string.sub(str, str_index + 1)

    return converted_md5
end

-- 滑块请求的校验
local function auth_check_sliding_req(rdsCache)

	local headers = ngx.req.get_headers() 
	local time_stamp = headers[TIME_STAMP_HEADER]
	local random = headers[RANDOM_NUM_HEADER]
	local token =  headers[TOKEN]
	
	-- 拼接数据
	local param = time_stamp .. "-" .. random .. "-" .. AUTH_SECRET;
	local origin_md5 = ngx.md5(param)
	
	-- 填充随机字符在随机的位置
	local converted_md5 = insert_char_Str(origin_md5, random, CHAR_BOARD_LIST)

	-- 判断加密是否正确
	if converted_md5 ~= token then
    	   return false, nil
	end

	-- 在redis查询是否有相同的请求
	local token_key = CC_TOKEN_PREFIX .. converted_md5

	
	local exist = rdsCache:exists(token_key)
	if exist == 1 then
    		return false, nil
    end
   
	return true, token_key
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
	ngx.log(ngx.ERR, "------------ slider ------------ redis连接失败")
    local ok, err = rdsCache:close()
end

if is_connected_succes then
	-- 判断是否是黑名单
	local clientIp = getClientIp()
	local isBlack = isBlackIp(rdsCache, clientIp)
	if isBlack then
		ngxBlock(rdsCache, NGINX_BLOCK_IP_BLACK)
	end
   
     -- 滑块请求合法性校验
	local is_auth_success, token= auth_check_sliding_req(rdsCache)
    if is_auth_success then
    	 -- 将token写redis
    	 rdsCache:set(token, 1)
	 rdsCache:expire(token_key, REDIS_TOKEN_TTL)

	 -- 写白明单，从滑块黑名单移除
	 rdsCache:sadd(CC_S_IP_WHITELIST, clientIp)
	 rdsCache:srem(CC_S_IP_SLIDER_BLACKLIST, clientIp)

	 -- 从访问黑名单移出，并清除该IP的所有访问记录
	 rdsCache:srem(CC_S_IP_BLACKLIST, clientIp)
	 local clientIp_uri_key_list = rdsCache:keys(clientIp .. "*")
	 if clientIp_uri_key_list then 
		for k, v in pairs(clientIp_uri_key_list) do
			rdsCache:del(v)
		end
	 end
	 
	 ngxBlock(rdsCache, NGINX_AUTH_SUCCESS)
    else
    	-- 写黑明单
    	rdsCache:sadd(CC_S_IP_SLIDER_BLACKLIST, clientIp) 
    	ngxBlock(rdsCache, NGINX_BLOCK_IP_BLACK)	
    end
end
