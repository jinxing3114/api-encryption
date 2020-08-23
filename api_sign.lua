local function msg(code, msg)
    ngx.status = code;
    ngx.print(msg);
    return ngx.exit(ngx.OK);
end

--监测是否为post请求
if ngx.req.get_method() ~= "POST" then
    return msg(500, "error1");
end
--监测post数据长度
ngx.req.read_body();
local bodyData = ngx.req.get_body_data();
if bodyData == nil or string.len(bodyData) < 32 then
    return msg(500, "error2");
end
--兼容IOS客户端，请求数据是base64结构
bodyData = ngx.decode_base64(bodyData);

--redis判断该请求是否可以请求
local redis = require "redis"
local red = redis:new()
red:set_timeout(1000) -- 1 sec
local bodyMd5 = ngx.md5(bodyData);
local redisKey = "api_body_sign_" .. bodyMd5
local ok, err = red:connect("127.0.0.1", 6379)
if not ok then
    return msg(500, 'error3');
end

--如果查询到该请求了，那么拒绝该请求的访问
local res, err1 = red:get(redisKey)
if not res or res == "" or res == ngx.null then
    --写入请求到redis服务器
    ok, err = red:set(redisKey, "1", "EX", "3600")
    if not ok then
        return msg(500, 'error4');
    end
else
    return msg(500, 'error5');
end

--截取数据前缀，重新组合为合法数据，并且获取到iv值
local tmpPre = {};
local tmpIv = {};
table.insert(tmpPre, string.sub(bodyData, 1, 1));
for i=2,33 do
    if i%2 == 0 then
        table.insert(tmpPre, string.sub(bodyData, i, i));
    else
        table.insert(tmpIv, string.sub(bodyData, i, i));
    end
end

local iv = table.concat(tmpIv);
--ngx.say(iv);
local content = table.concat(tmpPre) .. string.sub(bodyData, 34);
local key = "encrypt_key" .. string.sub(iv, 2, 16);
--ngx.say(key);
local aes = require "resty.aes";
local str = require "resty.string";
local aes_256_cbc_with_iv, aes_error = aes:new(key, nil, aes.cipher(256,"cbc"), {iv=iv});
if not aes_256_cbc_with_iv then
    return msg(503, "error2");
end
local decrypt = aes_256_cbc_with_iv:decrypt(content);
if decrypt == nil then
    return msg(504, "error3");
end
local time = string.sub(decrypt, -10);
time = tonumber(time);
local timeDiff = ngx.time() - time;
if timeDiff < -60 or timeDiff >= 60 then
    return msg(505, "error4");
end
--ngx.say(decrypt);
msg(200, "ok");
ngx.req.set_body_data(string.sub(decrypt, 1, -11));
--设置该请求为api请求，标记返回数据需要加密
ngx.ctx.bodyDecrypt = 1;