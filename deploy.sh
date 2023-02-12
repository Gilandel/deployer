#!/usr/bin/env bash

export GPG_TTY=$(tty)

export TEMP=${RUNNER_TEMP}/deployer_workspace
HOME=${GITHUB_WORKSPACE}
GNUPG=${HOME}/.gnupg/
GIT_USER=${GITHUB_REPOSITORY_OWNER}
REPO_SLUG=${GITHUB_REPOSITORY}
BRANCH=${GITHUB_REF_NAME}
if [ "$GITHUB_EVENT_NAME" = 'pull_request' ]; then PULL_REQUEST="true"; else PULL_REQUEST="false"; fi

MVN_SETTINGS=${TEMP}/settings.xml

echo "Prepare GnuPG directory: mkdir ${GNUPG}"
mkdir -p ${GNUPG}

echo "Prepare temporary directory: mkdir ${TEMP}"
mkdir -p ${TEMP}

echo "Prepare temporary directory: mkdir ${HOME}/.ssh"
mkdir -p ${HOME}/.ssh && chmod -R 600 ${HOME}/.ssh

function download {
	echo "Download ${DEPLOYER_URL}/$1"
	curl ${DEPLOYER_URL}/$1 -o ${TEMP}/$1
	if [ ! -f ${TEMP}/$1 ]; then echo "ERROR: Download ${DEPLOYER_URL}/$1 to $2/$1"; exit 1; fi
}

download pushingkey.enc ${TEMP};
download pubring.gpg ${GNUPG};
download secring.gpg.enc ${TEMP};
download settings.xml ${TEMP};

echo 'Start SSH agent'
eval "$(ssh-agent)"

echo 'Decrypt SSH key so we can sign artifact'
openssl aes-256-cbc -K ${ENCPRYPTED_KEY} -iv ${ENCPRYPTED_IV} -in ${TEMP}/secring.gpg.enc -out ${GNUPG}/secring.gpg -d

if [ $? -ne 0 ]; then echo "ERROR: Decrypt secring.gpg.enc"; exit $?; fi

echo 'Import GPG rings'
echo "$GPG_PASSPHRASE" | gpg --batch --yes --passphrase --import ${GNUPG}/pubring.gpg
echo "$GPG_PASSPHRASE" | gpg --batch --yes --passphrase --import ${GNUPG}/secring.gpg

DEBUG_PARAM=
if [ "$DEBUG" = 'true' ]; then
	DEBUG_PARAM="-e -X"
fi

if [ "$BRANCH" = 'master' ] && [ "$PULL_REQUEST" = 'false' ]; then
	echo "Build and deploy SNAPSHOT"
	
	mvn deploy -DskipTests=true -P sign,build-extras --settings ${MVN_SETTINGS} ${DEBUG_PARAM}
	
elif [ "$BRANCH" = 'release' ]; then

	echo 'Decrypt SSH key so we can push release to GIT repository'
	openssl aes-256-cbc -K ${ENCPRYPTED_KEY} -iv ${ENCPRYPTED_IV} -in ${TEMP}/pushingkey.enc -out ${TEMP}/pushing.key -d && \
	chmod 600 ${TEMP}/pushing.key
	
	if [ $? -ne 0 ]; then echo "ERROR: Decrypt pushingkey.enc"; exit $?; fi
	
	echo 'Import pushing key'
	ssh-add ${TEMP}/pushing.key
	
	echo 'Configure GIT'
	git config --global user.email "$GIT_EMAIL" && \
	git config --global user.name "$GIT_USER"

	GIT_LAST_LOG=$(git log --format=%B -n 1)
	
	if test "${GIT_LAST_LOG#*\[maven-release-plugin\]}" != "$GIT_LAST_LOG"; then
		echo "Do not release commits created by maven release plugin"
	else
		echo "Prepare and perform RELEASE"
		
		# Pipeline checkout the commit as detached head (which is normally what we
		# want) but maven release plugin does not like working in detached head
		# mode. This might be a problem if other commits have already been pushed
		# to the release branch, but in that case we will have problem anyway.
		echo 'Checkout and release'
		git checkout release
		
		if [ $? -ne 0 ]; then echo "ERROR: Git checkout release"; exit $?; fi
		
		# Prepare
		echo 'Prepare release'
		mvn release:clean release:prepare -B -P sign,build-extras --settings ${MVN_SETTINGS} ${DEBUG_PARAM}
			
		if [ $? -ne 0 ]; then echo "ERROR: Maven prepare"; exit $?; fi
		
		# Release
		echo 'Release'
		mvn release:perform -B -P sign,build-extras --settings ${MVN_SETTINGS} -Darguments="-DskipTests=true" ${DEBUG_PARAM}
		
		if [ $? -ne 0 ]; then echo "ERROR: Maven release"; exit $?; fi
		
		# Merge the release branch with master
		echo 'Merge release into master'
		git fetch origin +master:master && \
		git checkout master && \
		git merge release && \
		git push git@github.com:${REPO_SLUG}.git refs/heads/master:refs/heads/master
	fi
else
	echo "Only build"
fi

exit $?
