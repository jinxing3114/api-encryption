# api-encryption
API micro encryption

基于openresty，封装API接口解密，以及数据格式化
使用方法

使用redis抵御重放攻击
使用ras256加密，加密级别更高

iv以及部分key都是算法生成

校验时间戳，过期请求拒绝。

该功能的好处可以将不合法的请求拦截，减少后段处理压力，格式化数据

在nginx 站点配置文件中
location中开头增加
access_by_lua_file api_sign.lua;
