#!/usr/bin/env bash

# install JQ a JSON processor
apt-get install jq

# download the latest version of Codacity reporter
wget -q -O ~/codacy-coverage-reporter-assembly.jar $(curl -s https://api.github.com/repos/codacy/codacy-coverage-reporter/releases/latest | jq -r .assets[0].browser_download_url)

# Download missing dependencies
wget -q -O ~/activation.jar https://maven.repository.redhat.com/ga/javax/activation/activation/1.1.1.redhat-5/activation-1.1.1.redhat-5.jar