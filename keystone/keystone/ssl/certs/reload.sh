docker stop keystone
docker rm keystone
 docker run -d  --name keystone --network=host --restart unless-stopped -u root -v /apache2/:/var/log/apache2 -v /etc/keystone/credential-keys:/etc/keystone/credential-keys -v /etc/keystone/fernet-keys:/etc/keystone/fernet-keys -v /usr/share/docker/:/usr/share/docker/ -v /etc/localtime:/etc/localtime  -e KEYSTONE_START='START_KEYSTONE' docker-registry:4000/keystone:q


 docker cp keystone.conf  keystone:/etc/apache2/sites-enabled/

docker cp first_run.sh keystone:/root


docker cp apache2.conf keystone:/etc/apache2/
docker exec -it keystone bash
