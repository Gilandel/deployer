#!/usr/bin/env bash

# Run Codacity reporter
java -jar "$HOME/codacy-coverage-reporter-assembly.jar" report $*
