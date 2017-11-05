#!/usr/bin/env bash

# Run Codacity reporter
java -cp "$HOME/codacy-coverage-reporter-assembly.jar:$HOME/activation.jar" com.codacy.CodacyCoverageReporter $*