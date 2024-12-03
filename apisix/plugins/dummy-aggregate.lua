local httpc = require("resty.http").new()

-- Single-shot requests use the `request_uri` interface.
local res, err = httpc:request_uri("http://example.com/helloworld", {
    method = "POST",
    body = "a=1&b=2",
    headers = {
        ["Content-Type"] = "application/x-www-form-urlencoded",
    },
})
if not res then
    ngx.log(ngx.ERR, "request failed: ", err)
    return
end

-- At this point, the entire request / response is complete and the connection
-- will be closed or back on the connection pool.

-- The `res` table contains the expeected `status`, `headers` and `body` fields.
local status = res.status
local length = res.headers["Content-Length"]
local body   = res.body