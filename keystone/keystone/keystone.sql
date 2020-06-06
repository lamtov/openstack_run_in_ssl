CREATE DATABASE keystone;
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost'  IDENTIFIED BY "iVVWSMqdfXfuDGuzKIk7u1OwSXoeTokI";
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%'  IDENTIFIED BY "iVVWSMqdfXfuDGuzKIk7u1OwSXoeTokI";

set global max_connections = 5000;
# show variables like "max_connections";
