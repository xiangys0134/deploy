CREATE EXTERNAL TABLE `waf_logs_tablename`(
  `timestamp` bigint,
  `formatversion` int,
  `webaclid` string,
  `terminatingruleid` string,
  `terminatingruletype` string,
  `action` string,
  `terminatingrulematchdetails` array<
                                  struct<
                                    conditiontype:string,
                                    location:string,
                                    matcheddata:array<string>
                                        >
                                     >,
  `httpsourcename` string,
  `httpsourceid` string,
  `rulegrouplist` array<
                     struct<
                        rulegroupid:string,
                        terminatingrule:struct<
                           ruleid:string,
                           action:string,
                           rulematchdetails:string
                                               >,
                        nonterminatingmatchingrules:array<
                                                       struct<
                                                          ruleid:string,
                                                          action:string,
                                                          rulematchdetails:array<
                                                               struct<
                                                                  conditiontype:string,
                                                                  location:string,
                                                                  matcheddata:array<string>
                                                                     >
                                                                  >
                                                               >
                                                            >,
                        excludedrules:string
                           >
                       >,
  `ratebasedrulelist` array<
                        struct<
                          ratebasedruleid:string,
                          limitkey:string,
                          maxrateallowed:int
                              >
                           >,
  `nonterminatingmatchingrules` array<
                                  struct<
                                    ruleid:string,
                                    action:string
                                        >
                                     >,
  `httprequest` struct<
                      clientip:string,
                      country:string,
                      headers:array<
                                struct<
                                  name:string,
                                  value:string
                                      >
                                   >,
                      uri:string,
                      args:string,
                      httpversion:string,
                      httpmethod:string,
                      requestid:string
                      > 
)
ROW FORMAT SERDE 'org.openx.data.jsonserde.JsonSerDe'
WITH SERDEPROPERTIES (
 'paths'='action,formatVersion,httpRequest,httpSourceId,httpSourceName,nonTerminatingMatchingRules,rateBasedRuleList,ruleGroupList,terminatingRuleId,terminatingRuleMatchDetails,terminatingRuleType,timestamp,webaclId')
STORED AS INPUTFORMAT 'org.apache.hadoop.mapred.TextInputFormat'
OUTPUTFORMAT 'org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat'
LOCATION 's3://aws-waf-logs-fazzaco/2021/'