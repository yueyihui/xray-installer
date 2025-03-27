#!/bin/bash

bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ remove

# Remove any leftover Xray files or directories
sudo rm -rf /var/log/xray
