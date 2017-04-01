SBT_VERSION=0.13.13
SBT_DIRECTORY=$HOME/sbt
SBT_HOME=$SBT_DIRECTORY/sbt-launcher-packaging-$SBT_VERSION/bin
CCR_DIRECTORY=$HOME/ccr

# install sbt
mkdir -p $SBT_DIRECTORY
curl -L https://dl.bintray.com/sbt/native-packages/sbt/$SBT_VERSION/sbt-$SBT_VERSION.tgz > $SBT_DIRECTORY/sbt-$SBT_VERSION.tgz
tar -xzvf $SBT_DIRECTORY/sbt-$SBT_VERSION.tgz -C $SBT_DIRECTORY

# clone or pull codacity coverage reporter
if [ -e "$CCR_DIRECTORY/codacy-coverage-reporter-assembly.jar" ]; then
	cd $CCR_DIRECTORY
	git pull
else
	git clone https://github.com/codacy/codacy-coverage-reporter $CCR_DIRECTORY
	cd $CCR_DIRECTORY
fi

# build codacity coverage reporter
$SBT_HOME/sbt assembly
mv -f $CCR_DIRECTORY/target/codacy-coverage-reporter-assembly-*.jar $CCR_DIRECTORY/codacy-coverage-reporter-assembly.jar
