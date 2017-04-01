SBT_VERSION=0.13.13
SBT_DIRECTORY=$HOME/.sbt_bin
SBT_HOME=$SBT_DIRECTORY/sbt-launcher-packaging-$SBT_VERSION/bin
CCR_DIRECTORY=$HOME/ccr

# install sbt
mkdir -p $SBT_DIRECTORY
curl -L https://dl.bintray.com/sbt/native-packages/sbt/$SBT_VERSION/sbt-$SBT_VERSION.tgz > $SBT_DIRECTORY/sbt-$SBT_VERSION.tgz
tar -xzvf $SBT_DIRECTORY/sbt-$SBT_VERSION.tgz

# clone and build codacity coverage reporter
mkdir -p $CCR_DIRECTORY
git clone git@github.com:codacy/codacy-coverage-reporter.git $CCR_DIRECTORY

# build codacity coverage reporter
cd $CCR_DIRECTORY
$SBT_HOME/sbt assembly
mv $CCR_DIRECTORY/target/codacy-coverage-reporter-assembly-*.jar $CCR_DIRECTORY/codacy-coverage-reporter-assembly.jar
