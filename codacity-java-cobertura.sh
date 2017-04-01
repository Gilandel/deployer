VERSION=1.0.13
LANGUAGE=Java
INPUT=target/cobertura/coverage.xml

mvn org.apache.maven.plugins:maven-dependency-plugin:2.7:get -DgroupId=com.codacy -DartifactId=codacy-coverage-reporter -Dversion=$VERSION -Dtype=pom
mkdir lib
mvn org.apache.maven.plugins:maven-dependency-plugin:2.7:copy-dependencies -f /path/to/m2/repo/com/codacy/codacy-coverage-reporter/$VERSION/codacy-coverage-reporter-$VERSION.pom -DoutputDirectory=./lib

java -cp ./lib com.codacy.CodacyCoverageReporter -l $LANGUAGE -r $INPUT

rm -rf ./lib
