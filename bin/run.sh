#!/bin/bash

set -e

BP_DIR="/../" # absolute path
BIN_DIR=$BP_DIR/bin

# parse args
BUILD_DIR=$1
CACHE_DIR=$2
ENV_DIR=$3

WILDFLY_VERSION="12.0.0.Final"
WILDFLY_SHA1="b2039cc4979c7e50a0b6ee0e5153d13d537d492f"
MYSQL_DRIVER_VERSION="8.0.11"
MYSQL_DRIVER_SHA1="2c3d25fe1dfdd6496e0bbe47d67809f67487cfba"
JBOSS_HOME=".jboss/wildfly-${WILDFLY_VERSION}"

cd $BUILD_DIR

mkdir -p .jboss
echo -n "-----> Installing Wildfly ${WILDFLY_VERSION}... "
curl -O http://download.jboss.org/wildfly/$WILDFLY_VERSION/wildfly-$WILDFLY_VERSION.tar.gz
echo "downloaded"
sha1sum wildfly-$WILDFLY_VERSION.tar.gz | grep $WILDFLY_SHA1 > /dev/null 2>&1
echo "verified"
tar xf wildfly-$WILDFLY_VERSION.tar.gz
echo "extracted"
mv wildfly-$WILDFLY_VERSION $JBOSS_HOME
echo "moved"
rm wildfly-$WILDFLY_VERSION.tar.gz
echo "done"


echo -n "-----> Installing MySQL Wildfly module... "
curl -O http://central.maven.org/maven2/mysql/mysql-connector-java/$MYSQL_DRIVER_VERSION/mysql-connector-java-$MYSQL_DRIVER_VERSION.jar
echo "downloaded"
sha1sum mysql-connector-java-$MYSQL_DRIVER_VERSION.jar | grep $MYSQL_DRIVER_SHA1 > /dev/null 2>&1
echo "verified"
mv mysql-connector-java-$MYSQL_DRIVER_VERSION.jar $JBOSS_HOME
echo "moved"
nohup $JBOSS_HOME/bin/standalone.sh -b=0.0.0.0 -Djboss.http.port=8080 > /dev/null 2>&1 &
echo "initializing and waiting for wildfly standalone gets up..."
until $(curl --output /dev/null --silent --head --fail http://localhost:8080); do printf '.'; sleep 5; done
cat << EOF > /tmp/wildfly-mysql-connector-java-installer
connect
module add --name=com.mysql --resources=$JBOSS_HOME/mysql-connector-java-$MYSQL_DRIVER_VERSION.jar --dependencies=javax.api,javax.transaction.api
/subsystem=datasources/jdbc-driver=mysql:add(driver-name="mysql",driver-module-name="com.mysql",driver-class-name=com.mysql.cj.jdbc.Driver)
quit
EOF
$JBOSS_HOME/bin/jboss-cli.sh --file=/tmp/wildfly-mysql-connector-java-installer
echo "MySQL wildfly module installed successfully"
$JBOSS_HOME/bin/jboss-cli.sh --connect command=:shutdown
echo "wildfly server stopped"
cp /../standalone/standalone.xml $JBOSS_HOME/standalone/configuration/
echo "standalone.xml datasource configured"
rm $JBOSS_HOME/mysql-connector-java-$MYSQL_DRIVER_VERSION.jar
echo "done"

echo "-----> Creating configuration..."
if [ -f $BUILD_DIR/Procfile ]; then
  echo "        - Using existing process types"
else
  cat << EOF > $BUILD_DIR/Procfile
web: \$JBOSS_HOME/bin/standalone.sh -b=0.0.0.0 -Djboss.http.port=\$PORT
EOF
fi

cat << EOF > $BUILD_DIR/.profile.d/jboss.sh
export JBOSS_HOME=${JBOSS_HOME}
EOF