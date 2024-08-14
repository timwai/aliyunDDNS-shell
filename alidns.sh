#!/bin/bash
#
#####################################################################
#
#Author:                Tingjusting
#Email:                 tingjusting@gmail.com
#Date:                  2023-02-17
#FileName：             alidns.sh
#URL:                   https://github.com/aliyunDDNS-shell
#Description：          阿里云DDNS
#Copyright (C):         2023 All rights reserved
#Signature Api:         https://help.aliyun.com/document_detail/315526.html
#Alidns Api：           https://next.api.aliyun.com/document/Alidns/2015-01-09
#
#####################################################################

ACCESS_KEY_ID="你的AccessKeyId"
ACCESS_SECRET="你的AccessSecret"
DOMAIN_NAME="example.com"
RR="www"
TYPE="A"

while [[ $# -gt 0 ]];
do
  case $1 in
    -id|-AccessKeyId)
      ACCESS_KEY_ID=$2
      shift
      shift
      ;;
    -secret|-AccessSecret)
      ACCESS_SECRET=$2
      shift
      shift
      ;;
    -domain|-DomainName)
      DOMAIN_NAME=$2
      shift
      shift
      ;;
    -rr|-RR)
      RR=$2
      shift
      shift
      ;;
    -type|-Type)
      TYPE=$2
      shift
      shift
      ;;
    *)
      shift
      shift
    ;;
  esac
done

if [[ $TYPE == "AAAA" ]]; then
   #IP=`curl -sS https://ipv6.netarm.com/`
    IP=`ip -6 addr|grep dynamic|grep -m1 '/128'|awk '{print $2}'|cut -d'/' -f1`
    if [[ ! $IP ]]; then
      IP=`ip -6 addr|grep dynamic|grep -m1 '/64'|awk '{print $2}'|cut -d'/' -f1`
    fi
else
    IP=`curl -sS https://ipv4.netarm.com/`
fi

if [[ ! $IP ]]; then
    echo "Can not get the ip of type $TYPE"
    exit 1
fi

urlEncode() {
  # 将输入的字符串转换为16进制编码的值
  local length="${#1}"
  length=$((length-1))
  for i in $(seq 0 $length)
  do
    local c="${1:i:1}"
    case $c in
      [a-zA-Z0-9.~_-])
        printf "$c"
        ;;
      *)
        printf '%%%02X' "'$c"
        ;;
    esac
  done
}


DescribeDomainRecords(){
    URL_PARAMS="AccessKeyId=${ACCESS_KEY_ID}"
    URL_PARAMS="${URL_PARAMS}&Action=DescribeDomainRecords"
    URL_PARAMS="${URL_PARAMS}&DomainName=${DOMAIN_NAME}"
    URL_PARAMS="${URL_PARAMS}&Format=JSON"
    URL_PARAMS="${URL_PARAMS}&RRKeyWord=$RR"
    URL_PARAMS="${URL_PARAMS}&SignatureMethod=HMAC-SHA1"
    URL_PARAMS="${URL_PARAMS}&SignatureNonce="`date +%s%3N`
    URL_PARAMS="${URL_PARAMS}&SignatureVersion=1.0"
    URL_PARAMS="${URL_PARAMS}&Timestamp="`urlEncode $(date -u +"%Y-%m-%dT%H:%M:%SZ")`
    URL_PARAMS="${URL_PARAMS}&Type=$TYPE"
    URL_PARAMS="${URL_PARAMS}&Version=2015-01-09"

    STRING_To_SIGN="GET&%2F&`urlEncode ${URL_PARAMS}`"

    SIGNATURE=`echo -n ${STRING_To_SIGN} | openssl dgst -hmac "${ACCESS_SECRET}&" -sha1 -binary | openssl enc -base64`
    SIGNATURE=`urlEncode $SIGNATURE`

    URL_PARAMS="${URL_PARAMS}&Signature=${SIGNATURE}"
    curl -ss "http://alidns.aliyuncs.com?${URL_PARAMS}"
}

UpdateDomainRecord(){
    URL_PARAMS="AccessKeyId=${ACCESS_KEY_ID}"
    URL_PARAMS="${URL_PARAMS}&Action=UpdateDomainRecord"
    URL_PARAMS="${URL_PARAMS}&Format=JSON"
    URL_PARAMS="${URL_PARAMS}&RR=$RR"
    URL_PARAMS="${URL_PARAMS}&RecordId=$1"
    URL_PARAMS="${URL_PARAMS}&SignatureMethod=HMAC-SHA1"
    URL_PARAMS="${URL_PARAMS}&SignatureNonce="`date +%s%3N`
    URL_PARAMS="${URL_PARAMS}&SignatureVersion=1.0"
    URL_PARAMS="${URL_PARAMS}&Timestamp="`urlEncode $(date -u +"%Y-%m-%dT%H:%M:%SZ")`
    URL_PARAMS="${URL_PARAMS}&Type=$TYPE"
    URL_PARAMS="${URL_PARAMS}&Value=`urlEncode $IP`"
    URL_PARAMS="${URL_PARAMS}&Version=2015-01-09"

    STRING_To_SIGN="GET&%2F&`urlEncode ${URL_PARAMS}`"
    
    SIGNATURE=`echo -n ${STRING_To_SIGN} | openssl dgst -hmac "${ACCESS_SECRET}&" -sha1 -binary | openssl enc -base64`
    SIGNATURE=`urlEncode $SIGNATURE`

    URL_PARAMS="${URL_PARAMS}&Signature=${SIGNATURE}"
    curl -ss "http://alidns.aliyuncs.com?${URL_PARAMS}"
}

AddDomainRecord(){
    URL_PARAMS="AccessKeyId=${ACCESS_KEY_ID}"
    URL_PARAMS="${URL_PARAMS}&Action=AddDomainRecord"
    URL_PARAMS="${URL_PARAMS}&DomainName=${DOMAIN_NAME}"
    URL_PARAMS="${URL_PARAMS}&Format=JSON"
    URL_PARAMS="${URL_PARAMS}&RR=$RR"
    URL_PARAMS="${URL_PARAMS}&SignatureMethod=HMAC-SHA1"
    URL_PARAMS="${URL_PARAMS}&SignatureNonce="`date +%s%3N`
    URL_PARAMS="${URL_PARAMS}&SignatureVersion=1.0"
    URL_PARAMS="${URL_PARAMS}&Timestamp="`urlEncode $(date -u +"%Y-%m-%dT%H:%M:%SZ")`
    URL_PARAMS="${URL_PARAMS}&Type=$TYPE"
    URL_PARAMS="${URL_PARAMS}&Value=`urlEncode $IP`"
    URL_PARAMS="${URL_PARAMS}&Version=2015-01-09"

    STRING_To_SIGN="GET&%2F&`urlEncode ${URL_PARAMS}`"
    
    SIGNATURE=`echo -n ${STRING_To_SIGN} | openssl dgst -hmac "${ACCESS_SECRET}&" -sha1 -binary | openssl enc -base64`
    SIGNATURE=`urlEncode $SIGNATURE`

    URL_PARAMS="${URL_PARAMS}&Signature=${SIGNATURE}"
    curl -ss "http://alidns.aliyuncs.com?${URL_PARAMS}"
}

RECORDS=$(DescribeDomainRecords)

if echo $RECORDS|grep -q '"'$RR'"'; then
    if echo $RECORDS|grep -q '"'$IP'"'; then
        echo "$DOMAIN_NAME $IP"
        echo "The DNS record already exists."
        exit 1
    fi
    RECORD=`echo $RECORDS|sed 's/{"RR":"/\n\r{"RR":"/g'|sed 's/]},"PageNumber"/\n\r]},"PageNumber"/g'|grep '"'$RR'"'`
    RECORD=${RECORD#*'"RecordId":"'}
    RECORD_ID=${RECORD%'","TTL"'*}
    RESULT=`UpdateDomainRecord $RECORD_ID`
    if echo $RESULT|grep -q 'RecordId'; then
        echo "$DOMAIN_NAME $IP"
        echo "Add DNS record success."
    else
        echo "$DOMAIN_NAME $IP"
        echo "Add DNS record fail."
    fi
else
    AddDomainRecord
fi
