VERSION=1.0.13
LANGUAGE=Java
INPUT=target/cobertura/coverage.xml

curl -sL http://central.maven.org/maven2/com/codacy/codacy-coverage-reporter/$VERSION/codacy-coverage-reporter-$VERSION.jar > codacy-coverage-reporter.jar
java -jar codacy-coverage-reporter.jar com.codacy.CodacyCoverageReporter -l $LANGUAGE -r $INPUT
rm codacy-coverage-reporter.jar