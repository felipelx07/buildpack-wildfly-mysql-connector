# Wildfly Buildpack + MySQL module JDBC

Simple script for download and configure Wildfly Application Server + download and install MySQL Module Into. 
Ready to use! 

## Usage

1. Clone this project

2. Run /bin/run.sh file

3. Set the MySQL env variables:
- MYSQL_DB_HOST # e.g. jdbc:mysql://{HOST}:3306/{DATABASE}?useLegacyDatetimeCode=false&serverTimezone=UTC
- MYSQL_DB_USER # e.g. root
- MYSQL_DB_PASS # e.g. root
