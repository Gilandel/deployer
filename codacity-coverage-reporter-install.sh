#!/usr/bin/env bash

# install JQ a JSON processor
sudo apt-get install jq

# download the latest version of Codacity reporter
wget -O ~/codacy-coverage-reporter-assembly.jar $(curl https://api.github.com/repos/codacy/codacy-coverage-reporter/releases/latest | jq -r .assets[0].browser_download_url)