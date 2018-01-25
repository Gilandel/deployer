# A simple maven deployer for Travis jobs

Required properties (defined in Travis):
- DEPLOYER_URL: contains 4 files: (ex: https://raw.githubusercontent.com/Gilandel/deployer/master)
  - pushingkey.enc: the private key used to push modified files after releasing
  - pubring.gpg: the public key used to validate the jar signature
  - secring.gpg.enc: the private key used to sign jar
  - settings.xml: the maven user settings, where public repository is defined
- ENCPRYPTED_KEY: the encryption key
- ENCPRYPTED_IV: the encryption initialization vector
- GIT_EMAIL: Email used during the git push after releasing
- GIT_USER: User name used during the git push after releasing
- OSSRH_JIRA_USERNAME: OSS Repository Hosting user's name injected into settings.xml to stage the artifacts
- OSSRH_JIRA_PASSWORD: OSS Repository Hosting password injected into settings.xml to stage the artifacts
- DEBUG: if set to true, inject '-e -X' parameters into Maven commands (optional parameter)

## Prepare the encryption keys and signatures

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

## How to deploy to Maven Central

In your Travis file `.travis.yml`, add the following lines (example: [utils-assertor .travis.yml](https://github.com/Gilandel/utils-assertor/blob/master/.travis.yml)):
```yaml
after_success:
  # Stage artifacts
  - curl $DEPLOYER_URL/deploy.sh | bash
```

Don't forget to add distributionManagement, licenses... parts in your pom.xml, example: [utils project pom](https://github.com/Gilandel/utils/blob/master/pom.xml)

The logic is based on two branches, master (the develop branch) and release (the branch to release).
At each push on master branch, a snapshot will be deploy to OSSRH https://oss.sonatype.org/content/repositories/snapshots
At each merge on release branch, a release is launched and pushed to https://oss.sonatype.org/service/local/staging/deploy/maven2/ (the master branch is automatically merged post release).
After the first stage is completed and checked by the oss team, the release will be deployed to central maven repository (around 2 hours after).

## Codacity coverage reporter

In your Travis file `.travis.yml`, add Codacity reporter install step:
```yaml
install:
  # Install Codacity coverage reporter (install build reporter)
  - curl $DEPLOYER_URL/codacity-coverage-reporter-install.sh | sudo bash
```

Call the reporter and cleanup:
```yaml
after_success:
  # Call Codacity coverage reporter
  - curl $DEPLOYER_URL/codacity-coverage-reporter-runner.sh | bash -s -- -l Java -r target/site/jacoco/jacoco.xml
```

## License
Apache License, version 2.0