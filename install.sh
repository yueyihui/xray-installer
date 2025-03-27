#!/bin/bash

# Update package index and install dependencies
sudo apt-get update
sudo apt-get install -y jq openssl

bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install

json=$(curl -s https://raw.githubusercontent.com/yueyihui/xray-installer/main/config.json)

keys=$(xray x25519)
pk=$(echo "$keys" | awk '/Private key:/ {print $3}')
pub=$(echo "$keys" | awk '/Public key:/ {print $3}')
serverIp=$(curl -s ipv4.wtfismyip.com/text)
uuid=$(xray uuid)
shortId=$(openssl rand -hex 8)

port=443
sni=music.apple.com
email=

newJson=$(echo "$json" | jq \
    --arg pk "$pk" \
    --arg uuid "$uuid" \
    --arg port "$port" \
    --arg sni "$sni" \
    --arg email "$email" \
    '.inbounds[0].port= '"$(expr "$port")"' |
     .inbounds[0].settings.clients[0].email = $email |
     .inbounds[0].settings.clients[0].id = $uuid |
     .inbounds[0].streamSettings.realitySettings.dest = $sni + ":'$port'" |
     .inbounds[0].streamSettings.realitySettings.serverNames += ["'$sni'"] |
     .inbounds[0].streamSettings.realitySettings.privateKey = $pk |
     .inbounds[0].streamSettings.realitySettings.shortIds += ["'$shortId'"]')

echo "$newJson" | sudo tee /usr/local/etc/xray/config.json >/dev/null
sudo systemctl restart xray

echo "$serverIp: $port"
echo "uuid: $uuid"
echo "type: grpc"
echo "serviceName: grpc"
echo "security: reality"
echo "encryption: none"
echo "pubKey: $pub"
echo "fingerprint: chrome"
echo "sni: $sni"
echo "shortId: $shortId"

exit 0
