# A simple maven deployer for Travis jobs

Required properties (defined in Travis):
- DEPLOYER_URL: contains 4 files: (ex: https://raw.githubusercontent.com/Gilandel/deployer/master)
  - pushingkey.enc: the private key used to push modified files after releasing
  - pubring.gpg: the public key used to validate the jar signature
  - secring.gpg.enc: the private key used to sign jar
  - settings.xml: the maven user settings, where public repository is defined
- ENCPRYPTED_KEY: the encryption key
- ENCPRYPTED_IV: the encryption initilization vector
- GIT_EMAIL: Email used during the git push after releasing
- GIT_USER: User name used during the git push after releasing
- OSSRH_JIRA_USERNAME: OSS Repository Hosting username injected into settings.xml to stage the artifacts
- OSSRH_JIRA_PASSWORD: OSS Repository Hosting password injected into settings.xml to stage the artifacts
- DEBUG: if set to true, inject '-e -X' params into Maven commands (optional parameter)

## Encrypt 

For SSH key generation, follow [GITHUB tutorial](https://help.github.com/articles/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent/)

Create gpg key:
```
gpg --gen-key
```

Add a revocation certificate:
```
gpg --output revoke.asc --gen-revoke your@email.com
```

Check if pair private/public is generated:
```
gpg --list-key
-------------------------------
pub   4096R/XXXXXXXX 2017-03-17
uid                  Firstname Lastname (my comment) <your@email.com>
sub   4096R/YYYYYYYY 2017-03-17
```

Export keys (for both use pub key identifier):
```
gpg --output secring.gpg --export-secret-key XXXXXXXX
gpg --output pubring.gpg --export XXXXXXXX
```

Encode GITHUB keys:
```
openssl aes-256-cbc -in "~/.ssh/id_rsa" -out "pushingkey.enc" -p -e
```

Keep the result (ENCPRYPTED_KEY=key, ENCPRYPTED_IV=iv):
```
salt=XXXXXXXXXXXXXXXX
key=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
iv =XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
```

Encode the second file:
```
openssl aes-256-cbc -K $ENCPRYPTED_KEY -iv $ENCPRYPTED_IV -in "./secring.gpg" -out "secring.gpg.enc" -p -e
```

Do not forgot to distribute your public gpg signing key (pubring.gpg) on one of these keys servers for example:
- [keyserver.ubuntu.com](http://keyserver.ubuntu.com),
- [pgp.mit.edu](http://pgp.mit.edu),
- [keyserver.pgp.com](http://keyserver.pgp.com).

## Use it

In your Travis file `.travis.yml`:
```yaml
after_success:
  # Stage artifact to Sonatype OSSRH
  - curl $DEPLOYER_URL/deploy.sh | bash
```

## Codacity coverage reporter

In your Travis file `.travis.yml`, add SBT and Codacity coverage reporter caches and cleanup:
```yaml
cache:
  directories:
  # SBT
  - $HOME/.ivy2/cache
  # Maven
  - $HOME/.m2
  # SBT binaries
  - $HOME/sbt
  # Code coverage
  - $HOME/ccr

before_cache:
  # Cleanup the cached directories to avoid unnecessary cache updates
  - find $HOME/.ivy2/cache -name "ivydata-*.properties" -print -delete
  - find $HOME/.sbt        -name "*.lock"               -print -delete
```

Add Codacity reporter install step (install sbt + build reporter):
```yaml
before_install:
  # Install Codacity coverage reporter (get SBT + build reporter)
  - curl $DEPLOYER_URL/codacity-coverage-reporter-install.sh | bash
```

Call the reporter and cleanup:
```yaml
after_success:
  # Call Codacity coverage reporter
  - java -cp $HOME/ccr/codacy-coverage-reporter-assembly.jar com.codacy.CodacyCoverageReporter -l Java -r target/cobertura/coverage.xml
  - curl $DEPLOYER_URL/codacity-coverage-reporter-clean.sh | bash
```

## License
Apache License, version 2.0