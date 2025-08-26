#!/bin/bash
# 等待 Zabbix Server 启动完成
sleep 180

# Zabbix API 地址和认证信息
ZABBIX_URL="http://zabbix-web:8080/api_jsonrpc.php"
USER="Admin"
PASSWORD="zabbix"

# 自动注册策略参数
ZABBIX_AGENT_NAME="zabbix-agent"
HOST_METADATA="docker-agent"
HOSTGROUP_NAME="Linux servers"
TEMPLATE_NAME="Linux by Zabbix agent active"

# 1. 获取认证 Token
TOKEN=$(curl -s -X POST -H "Content-Type: application/json-rpc" -d '{
  "jsonrpc": "2.0",
  "method": "user.login",
  "params": {
    "username": "'"$USER"'",
    "password": "'"$PASSWORD"'"
  },
  "id": 1
}' $ZABBIX_URL | jq -r .result)

echo "获取到 Token: $TOKEN"

if [ "$TOKEN" == "null" ] || [ -z "$TOKEN" ]; then
    echo "登录 Zabbix API 失败"
    exit 1
fi

# 创建自动添加zabbix-agent主机
# 2. 获取 Docker 容器 IP 并推测网段
#MY_IP=$(hostname -i)
#NET_PREFIX=${MY_IP%.*}.0/24
#echo "Detected network: $NET_PREFIX"

# Zabbix 7.4
# --------------------------------
# 1. 获取 GROUP ID
# --------------------------------
GROUP_ID=$(curl -s \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "hostgroup.get",
    "params": {
      "filter": {
		"name": "'"$HOSTGROUP_NAME"'"
	  }
    },
    "id": 2
  }' $ZABBIX_URL | jq -r '.result[0].groupid')

if [ -z "$GROUP_ID" ]; then
    echo "获取主机组 ID 失败"
    exit 1
fi
echo "主机组 ID: $GROUP_ID"

# --------------------------------
# 2. 获取模板 ID
# --------------------------------
TEMPLATE_ID=$(curl -s -X POST \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
        "jsonrpc": "2.0",
        "method": "template.get",
        "params": {
			"filter": {
				"host": [
					"'"$TEMPLATE_NAME"'"
				]
			}
		},
        "id": 3
    }' $ZABBIX_URL | jq -r '.result[0].templateid')

if [ -z "$TEMPLATE_ID" ]; then
    echo "获取模板 ID 失败"
    exit 1
fi
echo "模板 ID: $TEMPLATE_ID"

# --------------------------------
# 3. 创建zabbix-agent主机动作
# --------------------------------
RESPONSE=$(curl -s -X POST \
    -H "Authorization: Bearer $TOKEN" \
    -H 'Content-Type: application/json' \
	-d '{
	  "jsonrpc": "2.0",
	  "method": "host.create",
	  "params": {
	    "host": "zabbix-agent",
	    "interfaces": [
	      {
	        "type": 1,
	        "main": 1,
	        "useip": 0,
	        "ip": "",
	        "dns": "zabbix-agent",
	        "port": "10050"
	      }
	    ],
	    "groups": [
	      {
	        "groupid": "'"$GROUP_ID"'"
	      }
	    ],
	    "templates": [
	      {
	        "templateid": "'"$TEMPLATE_ID"'"
	      }
	    ]
	  },
	  "id": 4
	}' $ZABBIX_URL)

echo "自动注册zabbix-agent结果:"
echo "$RESPONSE" | jq

# ----------------------------------------------------------------------
# 删除zabbix server默认监控的127.0.0.1:10050端口
# zabbix server上没有zabbix agent，所以没法监控127.0.0.1:10050
# ----------------------------------------------------------------------
# --------------------------------
# 1. 获取 HOST ID
# --------------------------------
HOST_ID=$(curl -s \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "host.get",
    "params": {
      "filter": {
		"host": "Zabbix server"
	  }
    },
    "id": 5
  }' $ZABBIX_URL | jq -r '.result[0].hostid')

if [ -z "$HOST_ID" ]; then
    echo "获取主机 ID 失败"
    exit 1
fi
echo "主机 ID: $HOST_ID"
# 获取该主机的接口（127.0.0.1:10050）
INTERFACES=$(curl -s -X POST \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
        "jsonrpc": "2.0",
        "method": "hostinterface.get",
        "params": {
			"hostids": [
				"'"$HOST_ID"'"
		    ]
		},
        "id": 6
    }' $ZABBIX_URL)

# 找出 127.0.0.1:10050 的接口 ID
IFACEID=$(echo $INTERFACES | jq -r '.result[] | select(.ip=="127.0.0.1" and .port=="10050") | .interfaceid')

if [ -z "$IFACEID" ]; then
    echo "没有找到 127.0.0.1:10050 的接口，可能已经被删除"
    exit 0
fi

# 删除该主机的接口（127.0.0.1:10050）
DELETE_RESULT=$(curl -s -X POST \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
        "jsonrpc": "2.0",
        "method": "hostinterface.delete",
        "params": [
			"'"$IFACEID"'"
		],
        "id": 7
    }' $ZABBIX_URL)

echo "删除127.0.0.1:10050结果：$DELETE_RESULT"
