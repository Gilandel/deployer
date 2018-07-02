#!/usr/bin/env bash

# install JQ a JSON processor
apt-get -y install jq

# get the latest version of Codacity reporter
data=$(curl -s https://api.github.com/repos/codacy/codacy-coverage-reporter/releases/latest)

# display JSON data (check purpose)
echo $data

# download the jar
wget -O ~/codacy-coverage-reporter-assembly.jar $(echo $data | jq -r .assets[0].browser_download_url)
