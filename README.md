# api-encryption
API micro encryption

基于openresty，封装API接口解密，以及数据格式化
使用方法


在nginx 站点配置文件中
location中开头增加
access_by_lua_file api_sign.lua;
