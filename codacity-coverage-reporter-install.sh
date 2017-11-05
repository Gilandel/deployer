SBT_VERSION=1.0.2
SBT_DIRECTORY=$HOME/sbt
SBT_HOME=$SBT_DIRECTORY/sbt-launcher-packaging-$SBT_VERSION/bin
CCR_DIRECTORY=$HOME/ccr

# install sbt
mkdir -p $SBT_DIRECTORY
curl -L https://github.com/sbt/sbt/releases/download/v$SBT_VERSION/sbt-$SBT_VERSION.tgz
tar -xzvf $SBT_DIRECTORY/sbt-$SBT_VERSION.tgz -C $SBT_DIRECTORY

# clone or pull codacity coverage reporter
if [ -d "$CCR_DIRECTORY/.git" ]; then
	cd $CCR_DIRECTORY
	git pull
else
	git clone https://github.com/codacy/codacy-coverage-reporter $CCR_DIRECTORY
	cd $CCR_DIRECTORY
fi

# build codacity coverage reporter
$SBT_HOME/sbt assembly
mv -f $CCR_DIRECTORY/target/codacy-coverage-reporter-assembly-*.jar $CCR_DIRECTORY/codacy-coverage-reporter-assembly.jar
