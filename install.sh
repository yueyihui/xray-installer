#!/bin/bash

PROTOCOL='xhttp'

judgment_parameters() {
  local local_install='0'
  local temp_version='0'
  while [[ "$#" -gt '0' ]]; do
    case "$1" in
    'xhttp')
      PROTOCOL='xhttp'
      ;;
    'grpc')
      PROTOCOL='grpc'
      ;;
    *)
      echo "$0: unknown option -- -"
      return 1
      ;;
    esac
    shift
  done
}

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Update package index and install dependencies
echo -e "${BLUE}Updating package index and installing dependencies...${NC}"
sudo apt-get update
sudo apt-get install -y jq openssl

echo -e "${BLUE}Installing Xray...${NC}"
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install

json=$(curl -s https://raw.githubusercontent.com/yueyihui/xray-installer/main/config.${PROTOCOL})

keys=$(xray x25519)
pk=$(echo "$keys" | awk '/Private key:/ {print $3}')
pub=$(echo "$keys" | awk '/Public key:/ {print $3}')
serverIp=$(curl -s ipv4.wtfismyip.com/text)
uuid=$(xray uuid)
shortId=$(openssl rand -hex 8)

# Default values
default_port=443

# Menu for port configuration
echo -e "${YELLOW}Please enter the port number you want to configure (default is $default_port):${NC}"
read -r input_port

if [[ -n "$input_port" && "$input_port" =~ ^[0-9]+$ ]]; then
    port=$input_port
else
    port=$default_port
fi

newJson=$(echo "$json" | jq \
    --arg pk "$pk" \
    --arg uuid "$uuid" \
    --arg port "$port" \
    --arg shortId "$shortId" \
    '.inbounds[0].port= '"$(expr "$port")"' |
     .inbounds[0].settings.clients[0].id = $uuid |
     .inbounds[0].streamSettings.realitySettings.privateKey = $pk |
     .inbounds[0].streamSettings.realitySettings.shortIds += ["'$shortId'"]')

echo "$newJson" | sudo tee /usr/local/etc/xray/config.json >/dev/null
sudo systemctl restart xray

echo -e "${GREEN}Configuration Complete!${NC}"
echo -e "${BLUE}Server IP: ${NC}$serverIp"
echo -e "${BLUE}Port: ${NC}$port"
echo -e "${BLUE}UUID: ${NC}$uuid"
echo -e "${BLUE}Type: ${NC}$PROTOCOL"

if [ $PROTOCOL == 'xhttp' ]; then
     echo -e "${BLUE}xhttp path: ${NC}/a2b71a4e6734cb00"
fi

if [ $PROTOCOL == 'grpc' ]; then
     echo -e "${BLUE}Service Name: ${NC}$PROTOCOL"
fi

echo -e "${BLUE}Security: ${NC}reality"
echo -e "${BLUE}Encryption: ${NC}none"
echo -e "${BLUE}Public Key: ${NC}$pub"
echo -e "${BLUE}Fingerprint: ${NC}chrome"
echo -e "${BLUE}Short ID: ${NC}$shortId"

exit 0
