#!/usr/bin/env bash

set -ev

DISTRIBUTION_HOME=${HOME}/build/${TRAVIS_REPO_SLUG}/distribution
MVN_SETTINGS=${DISTRIBUTION_HOME}/settings.xml

mkdir -p $DISTRIBUTION_HOME

curl -o "${DISTRIBUTION_HOME}/pubring.gpg" "${DEPLOYER_URL}/pubring.gpg"
curl -o "${DISTRIBUTION_HOME}/pushingkey.enc" "${DEPLOYER_URL}/pushingkey.enc"
curl -o "${DISTRIBUTION_HOME}/secring.gpg" "${DEPLOYER_URL}/secring.gpg"
curl -o "${MVN_SETTINGS}" "${DEPLOYER_URL}/settings.xml"

if [ "$TRAVIS_BRANCH" = 'master' ] && [ "$TRAVIS_PULL_REQUEST" = 'false' ]; then
	echo "Build and deploy SNAPSHOT"
	
	mvn deploy -DskipTests=true -P sign,build-extras --settings ${MVN_SETTINGS}
elif [ "$TRAVIS_BRANCH" = 'release' ]; then
	if [[ `git log --format=%B -n 1` == *"[maven-release-plugin]"* ]]; then
		echo "Do not release commits created by maven release plugin"
	else
		echo "Prepare and perform RELEASE"
		
		# Decrypt SSH key so we can push release to GitHub
		openssl aes-256-cbc -K $ENCPRYPTED_KEY -iv $ENCPRYPTED_IV -in distribution/pushingkey.enc -out ${HOME}/.ssh/id_rsa -d
		chmod 600 ${HOME}/.ssh/id_rsa
		
		git config --global user.email "$GIT_EMAIL"
		git config --global user.name "$GIT_USER"
		
		# Travis checkout the commit as detached head (which is normally what we
		# want) but maven release plugin does not like working in detached head
		# mode. This might be a problem if other commits have already been pushed
		# to the release branch, but in that case we will have problem anyway.
		git checkout release
		
		# Prepare and release
		mvn release:clean release:prepare -B -P sign,build-extras --settings ${MVN_SETTINGS}
		mvn release:perform -B -P sign,build-extras --settings ${MVN_SETTINGS} -Darguments="-DskipTests=true --settings ${MVN_SETTINGS}"
		
		# Merge the release branch with master
		git fetch origin +master:master
		git checkout master
		git merge release
		git push origin +master
	fi
else
	echo "Only build"
fi
