#!/bin/bash

rm -rf /svc/was/tomcat/servers/admin11/webapps/dbtest.war
rm -rf /svc/was/tomcat/servers/admin11/webapps/dbtest
cp target/dbtest.war /svc/was/tomcat/servers/admin11/webapps
chown tomcat:tomcat /svc/was/tomcat/servers/admin11/webapps/dbtest.war
