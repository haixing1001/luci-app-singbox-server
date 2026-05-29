#!/bin/sh
# Generate sing-box server config from /etc/config/singbox_server

CONF="singbox_server"

json_escape() {
	printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

uci_get() {
	uci -q get "$CONF.config.$1" 2>/dev/null || printf '%s' "$2"
}

log_level="$(uci_get log_level info)"
listen="$(uci_get listen '::')"
port="$(uci_get port 443)"
protocol="$(uci_get protocol vless)"
uuid="$(uci_get uuid '')"
password="$(uci_get password '')"
tls_enabled="$(uci_get tls_enabled 0)"
cert_file="$(uci_get cert_file /etc/singbox-server/cert.pem)"
key_file="$(uci_get key_file /etc/singbox-server/key.pem)"
server_name="$(uci_get server_name '')"
sniff="$(uci_get sniff 1)"

[ -n "$uuid" ] || uuid="00000000-0000-4000-8000-000000000000"
[ -n "$password" ] || password="changeme"

TLS_JSON=""
if [ "$tls_enabled" = "1" ]; then
	TLS_JSON=",\n      \"tls\": {\n        \"enabled\": true,\n        \"server_name\": \"$(json_escape "$server_name")\",\n        \"certificate_path\": \"$(json_escape "$cert_file")\",\n        \"key_path\": \"$(json_escape "$key_file")\"\n      }"
fi

case "$protocol" in
	vless)
		cat <<JSON
{
  "log": {
    "level": "$(json_escape "$log_level")",
    "timestamp": true
  },
  "inbounds": [
    {
      "type": "vless",
      "tag": "vless-in",
      "listen": "$(json_escape "$listen")",
      "listen_port": $port,
      "sniff": $([ "$sniff" = "1" ] && echo true || echo false),
      "users": [
        {
          "uuid": "$(json_escape "$uuid")",
          "flow": ""
        }
      ]$TLS_JSON
    }
  ],
  "outbounds": [
    {
      "type": "direct",
      "tag": "direct"
    }
  ]
}
JSON
		;;
	trojan)
		cat <<JSON
{
  "log": {
    "level": "$(json_escape "$log_level")",
    "timestamp": true
  },
  "inbounds": [
    {
      "type": "trojan",
      "tag": "trojan-in",
      "listen": "$(json_escape "$listen")",
      "listen_port": $port,
      "sniff": $([ "$sniff" = "1" ] && echo true || echo false),
      "users": [
        {
          "password": "$(json_escape "$password")"
        }
      ]$TLS_JSON
    }
  ],
  "outbounds": [
    {
      "type": "direct",
      "tag": "direct"
    }
  ]
}
JSON
		;;
	shadowsocks)
		cat <<JSON
{
  "log": {
    "level": "$(json_escape "$log_level")",
    "timestamp": true
  },
  "inbounds": [
    {
      "type": "shadowsocks",
      "tag": "ss-in",
      "listen": "$(json_escape "$listen")",
      "listen_port": $port,
      "method": "2022-blake3-aes-128-gcm",
      "password": "$(json_escape "$password")"
    }
  ],
  "outbounds": [
    {
      "type": "direct",
      "tag": "direct"
    }
  ]
}
JSON
		;;
	*)
		echo "unsupported protocol: $protocol" >&2
		exit 1
		;;
esac
