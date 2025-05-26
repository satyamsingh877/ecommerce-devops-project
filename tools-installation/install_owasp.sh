#!/bin/bash
echo "Installing OWASP ZAP..."
sudo apt-get update
sudo apt-get install -y default-jre
ZAP_VERSION=2.12.0
wget https://github.com/zaproxy/zaproxy/releases/download/v$ZAP_VERSION/ZAP_$ZAP_VERSION\_Linux.tar.gz
tar -xvf ZAP_$ZAP_VERSION\_Linux.tar.gz
sudo mv ZAP_$ZAP_VERSION /opt/zaproxy
sudo ln -s /opt/zaproxy/zap.sh /usr/local/bin/zap
echo "OWASP ZAP installed"
