docker stop horizon
docker rm horizon
docker run -d --name horizon --network=host --restart unless-stopped -u root -v /var/log/docker/apache2:/var/log/apache2 -v /usr/share/docker/:/usr/share/docker/ -v /etc/localtime:/etc/localtime -e HORIZON_START='START_HORIZON' docker-registry:4000/horizon:q 
docker   cp  settings.py horizon:/usr/share/openstack-dashboard/openstack_dashboard/

docker cp ca.pem  horizon:/etc/ssl/certs/ca-certificates.crt

docker restart horizon
