Top requesting IP in any 5 min period between two dates:

================================================
SELECT
  httprequest.clientip,
  COUNT(*) AS "count"
FROM "awswaflogs"."waf_logs_"
WHERE from_unixtime(timestamp/1000) BETWEEN TIMESTAMP '2021-02-18 00:00:00' AND TIMESTAMP '2021-02-19 00:09:59'
GROUP BY httprequest.clientip, FLOOR("timestamp"/(1000*60*5))
ORDER BY count DESC
LIMIT 500;
================================================

Top requesting IP+URI...:

================================================
SELECT
  httprequest.clientip,
  httprequest.uri,
  COUNT(*) AS "count"
FROM "awswaflogs"."waf_logs_"
WHERE from_unixtime(timestamp/1000) BETWEEN TIMESTAMP '2021-02-18 00:00:00' AND TIMESTAMP '2021-02-19 00:09:59'
GROUP BY httprequest.clientip, httprequest.uri, FLOOR("timestamp"/(1000*60*5))
ORDER BY count DESC
LIMIT 500;
================================================


Top requesting IP+User-Agent...:

================================================
SELECT
  httprequest.clientip,
  header.value,
  COUNT(*) AS "count"
FROM "awswaflogs"."waf_logs_", UNNEST(httprequest.headers) as t(header)
WHERE
    from_unixtime(timestamp/1000) BETWEEN TIMESTAMP '2021-02-18 00:00:00' AND TIMESTAMP '2021-02-19 00:09:59'
  AND
    header.name = 'User-Agent'
GROUP BY httprequest.clientip, header.value, FLOOR("timestamp"/(1000*60*5))
ORDER BY count DESC
LIMIT 500;
================================================

Top requesting IP+Method...:

================================================
SELECT
  httprequest.clientip,
  httprequest.httpmethod,
  COUNT(*) AS "count"
FROM "awswaflogs"."waf_logs_"
WHERE from_unixtime(timestamp/1000) BETWEEN TIMESTAMP '2021-02-18 00:00:00' AND TIMESTAMP '2021-02-19 00:09:59'
GROUP BY httprequest.clientip, httprequest.httpmethod, FLOOR("timestamp"/(1000*60*5))
ORDER BY count DESC
LIMIT 500;
================================================


Top requesting IP+URI+User-Agent...:

================================================
SELECT
  httprequest.clientip,
  httprequest.uri,
  header.value,
  COUNT(*) AS "count"
FROM "awswaflogs"."waf_logs_", UNNEST(httprequest.headers) as t(header)
WHERE
    from_unixtime(timestamp/1000) BETWEEN TIMESTAMP '2021-02-18 00:00:00' AND TIMESTAMP '2021-02-19 00:09:59'
  AND
    header.name = 'User-Agent'
GROUP BY httprequest.clientip, httprequest.uri, header.value, FLOOR("timestamp"/(1000*60*5))
ORDER BY count DESC
LIMIT 500;
================================================

Top requesting IP+URI+Method...:

================================================
SELECT
  httprequest.clientip,
  httprequest.uri,
  httprequest.httpmethod,
  COUNT(*) AS "count"
FROM "awswaflogs"."waf_logs_"
WHERE from_unixtime(timestamp/1000) BETWEEN TIMESTAMP '2021-02-18 00:00:00' AND TIMESTAMP '2021-02-19 00:09:59'
GROUP BY httprequest.clientip, httprequest.uri, httprequest.httpmethod, FLOOR("timestamp"/(1000*60*5))
ORDER BY count DESC
LIMIT 500;
================================================

Top requesting IP+URI+Method+User-Agent...:

================================================
SELECT
  httprequest.clientip,
  httprequest.uri,
  httprequest.httpmethod,
  header.value,
  COUNT(*) AS "count"
FROM "awswaflogs"."waf_logs_", UNNEST(httprequest.headers) as t(header)
WHERE
    from_unixtime(timestamp/1000) BETWEEN TIMESTAMP '2021-02-18 00:00:00' AND TIMESTAMP '2021-02-19 00:09:59'
  AND
    header.name = 'User-Agent'
GROUP BY httprequest.clientip, httprequest.uri, httprequest.httpmethod, header.value, FLOOR("timestamp"/(1000*60*5))
ORDER BY count DESC
LIMIT 500;
================================================

Top requesting XFF IP...:

================================================
SELECT
  header.value,
  COUNT(*) AS "count"
FROM "awswaflogs"."waf_logs_", UNNEST(httprequest.headers) as t(header)
WHERE
    from_unixtime(timestamp/1000) BETWEEN TIMESTAMP '2021-02-18 00:00:00' AND TIMESTAMP '2021-02-19 00:09:59'
  AND
    header.name = 'X-Forwarded-For'
GROUP BY header.value, FLOOR("timestamp"/(1000*60*5))
ORDER BY count DESC
LIMIT 500;
================================================

Top requesting XFF IP... ordered by Client IP:

================================================
SELECT
  httprequest.clientip,
  header.value,
  COUNT(*) AS "count"
FROM "awswaflogs"."waf_logs_", UNNEST(httprequest.headers) as t(header)
WHERE
    from_unixtime(timestamp/1000) BETWEEN TIMESTAMP '2021-02-18 00:00:00' AND TIMESTAMP '2021-02-19 00:09:59'
  AND
    header.name = 'X-Forwarded-For'
GROUP BY httprequest.clientip, header.value, FLOOR("timestamp"/(1000*60*5))
ORDER BY count DESC
LIMIT 500;
================================================

Top country...:

================================================
SELECT
  httprequest.country,
  COUNT(*) AS "count"
FROM "awswaflogs"."waf_logs_"
WHERE from_unixtime(timestamp/1000) BETWEEN TIMESTAMP '2021-02-18 00:00:00' AND TIMESTAMP '2021-02-19 00:09:59'
GROUP BY httprequest.country, FLOOR("timestamp"/(1000*60*5))
ORDER BY count DESC
LIMIT 500;
================================================

Top country+clientip...:

================================================
SELECT
  httprequest.country,
  httprequest.clientip,
  COUNT(*) AS "count"
FROM "awswaflogs"."waf_logs_"
WHERE from_unixtime(timestamp/1000) BETWEEN TIMESTAMP '2021-02-18 00:00:00' AND TIMESTAMP '2021-02-19 00:09:59'
GROUP BY httprequest.country, httprequest.clientip, FLOOR("timestamp"/(1000*60*5))
ORDER BY count DESC
LIMIT 500;
================================================








