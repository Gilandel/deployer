#!/usr/bin/env bash

# install JQ a JSON processor
apt-get -y install jq

# get the latest version of Codacity reporter
data=$(curl -s https://api.github.com/repos/codacy/codacy-coverage-reporter/releases/latest)

# display JSON data (check purpose)
echo $data

# download the jar
wget -O ~/codacy-coverage-reporter-assembly.jar $(echo $data | jq -r .assets[0].browser_download_url)

# Download missing dependencies
wget -O ~/activation.jar https://maven.repository.redhat.com/ga/javax/activation/activation/1.1.1.redhat-5/activation-1.1.1.redhat-5.jar
