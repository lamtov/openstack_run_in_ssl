CREATE DATABASE nova_api;
CREATE DATABASE nova;
CREATE DATABASE nova_cell0;

GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'localhost' IDENTIFIED BY "tDYYivjrHo749yokhU7utc2GLlJezi14";
GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'%' IDENTIFIED BY "tDYYivjrHo749yokhU7utc2GLlJezi14";
GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'localhost'  IDENTIFIED BY "tDYYivjrHo749yokhU7utc2GLlJezi14";
GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'%' IDENTIFIED BY "tDYYivjrHo749yokhU7utc2GLlJezi14";
GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'localhost' IDENTIFIED BY "tDYYivjrHo749yokhU7utc2GLlJezi14";
GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'%' IDENTIFIED BY "tDYYivjrHo749yokhU7utc2GLlJezi14";
