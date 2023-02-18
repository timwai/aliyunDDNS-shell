**脚本全部使用基础的命令实现，支持在openwrt中使用** 

修改以下参数为你自己的参数
>ACCESS_KEY_ID="你的AccessKeyId"<br>
ACCESS_SECRET="你的AccessSecret"<br>
DOMAIN_NAME="example.com"<br>
RR="www"<br>
TYPE="A"

也可在执行时覆盖以上参数
```shell
sh alidns.sh -rr www -domian examole.com -type A -id 你的AccessKeyId -secret 你的AccessSecret
```
