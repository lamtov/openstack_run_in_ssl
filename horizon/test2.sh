docker stop horizon
docker rm horizon
docker run -d --name horizon --network=host --restart unless-stopped -u root -v /var/log/docker/apache2:/var/log/apache2 -v /usr/share/docker/:/usr/share/docker/ -v /etc/localtime:/etc/localtime -e HORIZON_START='START_HORIZON' docker-registry:4000/horizon:q




#docker cp   /usr/share/docker/horizon/openstack-dashboard/local_settings.py   horizon:/etc/openstack-dashboard/

#docker cp   openstack-dashboard.conf horizon:/etc/apache2/conf-enabled/

#docker restart horizon


