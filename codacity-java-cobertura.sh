VERSION=1.0.13
LANGUAGE=Java
INPUT=target/cobertura/coverage.xml

mvn org.apache.maven.plugins:maven-dependency-plugin:3.0.0:get -DgroupId=com.codacy -DartifactId=codacy-coverage-reporter -Dversion=$VERSION -Dtype=pom
mkdir lib
mvn org.apache.maven.plugins:maven-dependency-plugin:3.0.0:copy-dependencies -f $HOME/.m2/repository/com/codacy/codacy-coverage-reporter/$VERSION/codacy-coverage-reporter-$VERSION.pom -DoutputDirectory=./lib

ls -lth ./lib

java -cp lib/. com.codacy.CodacyCoverageReporter -l $LANGUAGE -r $INPUT

rm -rf ./lib
