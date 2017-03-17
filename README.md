# A simple maven deployer for Travis jobs

Required properties (defined in Travis):
- DEPLOYER_URL: contains 4 files: (ex: https://raw.githubusercontent.com/Gilandel/deployer/master)
  - pushingkey.enc: the private key used to push modified files after releasing
  - pubring.gpg: the public key used to validate the jar signature
  - secring.gpg.enc: the private key used to sign jar
  - settings.xml: the maven user settings, where public repository is defined
- ENCPRYPTED_KEY: 
- ENCPRYPTED_IV
- GIT_EMAIL: Property used during the pushing of modified files after releasing
- GIT_USER: Property used during the pushing of modified files after releasing
- OSSRH_JIRA_USERNAME: OSSRH username injected into settings.xml
- OSSRH_JIRA_PASSWORD: OSSRH password injected into settings.xml
- GROUP_ID_PATH: the group identifier to clean on the travis cache (ex: fr/landel/utils)

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

Encode keys:
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

In your Travis file:
```
after_success:
  - curl https://raw.githubusercontent.com/Gilandel/deployer/master/deploy.sh | sh
```

## License
See [main project license](https://github.com/Gilandel/utils/blob/master/LICENSE): Apache License, version 2.0