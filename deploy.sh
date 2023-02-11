#!/usr/bin/env bash

export GPG_TTY=$(tty)

HOME=${GITHUB_WORKSPACE}
GIT_USER=${GITHUB_REPOSITORY_OWNER}
REPO_SLUG=${GITHUB_REPOSITORY}
BRANCH=${GITHUB_REF_NAME}
if [ "$GITHUB_EVENT_NAME" = 'pull_request' ]; then PULL_REQUEST="true"; else PULL_REQUEST="false"; fi

DISTRIBUTION_HOME=${HOME}/build/${REPO_SLUG}/distribution
MVN_SETTINGS=${DISTRIBUTION_HOME}/settings.xml

mkdir -p ${DISTRIBUTION_HOME}

function download {
	echo "Download ${DEPLOYER_URL}/$1"
	curl ${DEPLOYER_URL}/$1 -o ${DISTRIBUTION_HOME}/$1
	if [ ! -f ${DISTRIBUTION_HOME}/$1 ]; then echo "ERROR: Download ${DEPLOYER_URL}/$1 to ${DISTRIBUTION_HOME}/$1"; exit 1; fi
}

download pushingkey.enc;
download pubring.gpg;
download secring.gpg.enc;
download settings.xml;

# Decrypt SSH key so we can sign artifact
openssl aes-256-cbc -K ${ENCPRYPTED_KEY} -iv ${ENCPRYPTED_IV} -in ${DISTRIBUTION_HOME}/secring.gpg.enc -out ${DISTRIBUTION_HOME}/secring.gpg -d

gpg --import pubring.gpg
gpg --import secring.gpg

if [ $? -ne 0 ]; then echo "ERROR: Decrypt secring.gpg.enc"; exit $?; fi

DEBUG_PARAM=
if [ "$DEBUG" = 'true' ]; then
	DEBUG_PARAM="-e -X"
fi

if [ "$BRANCH" = 'master' ] && [ "$PULL_REQUEST" = 'false' ]; then
	echo "Build and deploy SNAPSHOT"
	
	mvn deploy -DskipTests=true -P sign,build-extras --settings ${MVN_SETTINGS} ${DEBUG_PARAM}
elif [ "$BRANCH" = 'release' ]; then
	GIT_LAST_LOG=$(git log --format=%B -n 1)
	
	if test "${GIT_LAST_LOG#*\[maven-release-plugin\]}" != "$GIT_LAST_LOG"; then
		echo "Do not release commits created by maven release plugin"
	else
		echo "Prepare and perform RELEASE"
		
		# Decrypt SSH key so we can push release to GitHub
		openssl aes-256-cbc -K ${ENCPRYPTED_KEY} -iv ${ENCPRYPTED_IV} -in ${DISTRIBUTION_HOME}/pushingkey.enc -out ${HOME}/.ssh/id_rsa -d && \
		chmod 600 ${HOME}/.ssh/id_rsa
		
		if [ $? -ne 0 ]; then echo "ERROR: Decrypt pushingkey.enc"; exit $?; fi
		
		git config --global user.email "$GIT_EMAIL" && \
		git config --global user.name "$GIT_USER"
		
		# Travis checkout the commit as detached head (which is normally what we
		# want) but maven release plugin does not like working in detached head
		# mode. This might be a problem if other commits have already been pushed
		# to the release branch, but in that case we will have problem anyway.
		git checkout release
		
		if [ $? -ne 0 ]; then echo "ERROR: Git checkout release"; exit $?; fi
		
		# Prepare
		mvn release:clean release:prepare -B -P sign,build-extras --settings ${MVN_SETTINGS} ${DEBUG_PARAM}
			
		if [ $? -ne 0 ]; then echo "ERROR: Maven prepare"; exit $?; fi
		
		# Release
		mvn release:perform -B -P sign,build-extras --settings ${MVN_SETTINGS} -Darguments="-DskipTests=true" ${DEBUG_PARAM}
		
		if [ $? -ne 0 ]; then echo "ERROR: Maven release"; exit $?; fi
		
		# Merge the release branch with master
		git fetch origin +master:master && \
		git checkout master && \
		git merge release && \
		git push git@github.com:${REPO_SLUG}.git refs/heads/master:refs/heads/master
	fi
else
	echo "Only build"
fi

exit $?
