
# Read PDF document in https://www.slideshare.net/lamto01111995/run-openstack-with-ssl
# Openstack SSL

## 1. Tạo các file Privacy Enhanced Mail (PEM)

#### Sử dụng OpenSSL để sinh các file certificates.

####  Root_CA.pem

####  CSR: Certificate Signing Request

####  private_key.pem

####  server_cert.pem

### 1.1 Root SSL certificate:

#### + Hệ thống SSL xây dựng trên mô hình các quan hệ hình thành từ sự tin tưởng (chain of

#### trust).

#### + Một Root SSL certificate (Root_CA.pem) là một chứng chỉ được cấp bởi một cơ quan

#### chứng nhận tin cậy. Trong hệ thống SSL, mọi user đều có thể tạo signing key và một chứng chỉ

#### với chữ ký đó, tuy nhiên chứng chỉ này chỉ được Browsers tin tưởng khi nó được trực tiếp ký

#### bởi một cơ quan chứng nhận tin cậy.

#### + Danh sách các Root CA tương ứng với các cơ quan chứng nhận tin cậy được lưu trong

#### các file:

- **redhat** : /etc/ssl/certs/ca-bundle.crt
- **ubuntu** : /etc/ssl/certs/ca-certificates.crt

#### + Khi một thiết bị cần xác minh một chứng chỉ, nó sẽ lấy ra thông tin tổ chức phát hành

#### chứng chỉ và đối chiếu với danh sách các cơ quan chứng nhận tin cậy (trusted certificate

#### authority). Nếu tổ chức phát hành chứng chỉ không có trong danh sách thì sẽ truy vấn lên tổ

#### chức cấp trên cấp phép cho tổ chức này, cho đến khi lên top mà vẫn không có trong danh sách

#### thì reject.

#### Các bước tạo local RootCA:

```bash
openssl genrsa -des3 -out rootCA.key 2048
openssl req -x509 -new -nodes -key rootCA.key -sha256 -days 1024
```
- out rootCA.pem


### 1.2 Certificate Signing Request:

#### Là file mã hóa lưu thông tin tên công ty và domain

### 1.3 Private_key:

#### Sử dụng để ký vào Certificate Signing Request và xác thực các kết nối tới server.

```
openssl req -newkey rsa:2048 -keyout private_key.pem -keyform PEM
out cert_req.pem -outform PEM -config cert_req.conf -nodes
```
### 1.4 Server SSL Certificate:

#### Là SSL certificate của server có chứa các thông tin xác thực cho server như (common

#### name, subject name). Server_ssl_cert còn chứa cả public_key tương ứng với

#### private_key ở trong đó. public_key sau này sẽ được dùng trong giao thức ssl handshake

#### với client.

```bash
openssl x509 -req -in cert_req.pem -CA rootCA.pem -CAkey
rootCA.key -CAcreateserial -out server.pem -outform PEM -days500 - sha256 -extfile v3.ext
```

### 1.5 Luồng hoạt động:

- **Client** kết nối tới server
- **Server** gửi client **public_key**
- **Client** dùng danh sách **Trusted CA** xác minh Server.
- **Client** tạo một số ngẫu nhiên **N** và mã hóa số đó với **public_key**
- **Server** giải mã với **private_key** và áp đặt một hàm cho số đó **F(N)** ví dụ

#### F(N)=N+1 , sử dụng private_key để mã hóa F(N) và gửi lại cho client

- **Client** giải mã với **public_key** , đọc xem **F(N)** có đúng như mong đợi và xác minh

#### Server. (Chỉ có Server mới có thể gửi đúng F(N) cho client vì N là ngẫu nhiên)

- **Client** và **Server** tạo mọt **session_key** rồi giao tiếp thông qua **session_key** này.

#### **** Vì lý do Root_CA được tạo thủ công nội bộ không do một cơ quan nào xác minh nên các

#### browser sẽ không công nhận certificate được tạo từ Root_CA này.

####  Tự bổ xung Root_CA.pem vào các file chứa danh sách Trusted CA

- **redhat** : /etc/ssl/certs/ca-bundle.crt
- **ubuntu** : /etc/ssl/certs/ca-certificates.crt


## 2. Sử dụng các file PEM trong Openstack

### 2.1 Keystone

- Đặt các file **ca.pem** , **key.pem** và **cert.pem** vào thư mục
**/usr/share/docker/keystone/keystone/ssl/cert/**
- Update danh sách trusted CA trong keystone container:

**docker cp ca.pem keystone:/etc/ssl/certs/ca-certificates.crt**

- Bổ xung SSL và Apache2 trong Keystone Docker:

```bash
docker cp keystone.conf keystone:/etc/apache2/sites-enabled/
Listen 5000
<VirtualHost *:5000>
WSGIScriptAlias / /usr/bin/keystone-wsgi-public
WSGIDaemonProcess keystone-public processes=5 threads=1 user=keystone
group=keystone display-name=%{GROUP}
WSGIProcessGroup keystone-public
WSGIApplicationGroup %{GLOBAL}
WSGIPassAuthorization On
LimitRequestBody 114688
<IfVersion >= 2.4>
ErrorLogFormat "%{cu}t %M"
</IfVersion>
ErrorLog /var/log/apache2/keystone.log
CustomLog /var/log/apache2/keystone_access.log combined
```
```bash
<Directory /usr/bin>
<IfVersion >= 2.4>
Require all granted
</IfVersion>
<IfVersion < 2.4>
Order allow,deny
Allow from all
</IfVersion>
</Directory>
SSLEngine on
SSLCipherSuite
ECDH+AESGCM:DH+AESGCM:ECDH+AES256:DH+AES256:ECDH+AES128:DH+AES:ECDH+3DES:DH+3DES:RSA
+AESGCM:RSA+AES:RSA+3DES:!aNULL:!MD5:!DSS:!RC
SSLCertificateKeyFile /etc/keystone/ssl/certs/key.pem
SSLCertificateFile /etc/keystone/ssl/certs/cert.pem
SSLCACertificateFile /etc/keystone/ssl/certs/ca.pem
```
```bash
Alias /identity /usr/bin/keystone-wsgi-public
<Location /identity>
SetHandler wsgi-script
Options +ExecCGI
WSGIProcessGroup keystone-public
WSGIApplicationGroup %{GLOBAL}
WSGIPassAuthorization On
</Location>
</VirtualHost>
```
- Đổi tên ServerName tương ứng với tên server được cert.pem xác thực (“ **controller** ”)

```bash
docker cp apache2.conf keystone:/etc/apache2/
ServerName local -- ServerName controller
```

- Reload lại apache2 trong docker container keystone:

```bash
docker exec –it keystone bash
sudo a2enmod ssl
# Để cho phép apache2 sử dụng SSL service, tránh lỗi khi chạy SSLEngine on
sudo service apache2 restart
```
- Sửa lại Openstack Endpoint sang https:
    **Mysql:**
```bash
UPDATE keystone.endpoint SET url = "https://controller:5000/v3" WHERE
url="http://controller:5000/v3/";
UPDATE keystone.endpoint SET url = "https://controller:8774/v2.1" WHERE
url="http://controller:8774/v2.1";
UPDATE keystone.endpoint SET url = "https://controller:8778" WHERE
url="http://controller:8778";
UPDATE keystone.endpoint SET url = "https://controller:9292" WHERE
url="http://controller:9292";
UPDATE keystone.endpoint SET url = "https://controller:9696" WHERE
url="http://controller:9696";
```
- **Sửa lại Openrc:**

```bash
export OS_AUTH_URL=https://controller:5000/v
```

### 2.2 Horizon:

- Đặt các file **ca.pem** , **key.pem** và **cert.pem** vào thư mục
**/usr/share/docker/horizon/openstack-dashboard/ssl/cert/**
- Update danh sách trusted CA trong horizon container:

**docker cp ca.pem horizon:/etc/ssl/certs/ca-certificates.crt**

- Bổ xung SSL và Apache2 trong Horizon Docker:

```bash
docker cp openstack-dashboard.conf horizon:/etc/apache2/conf-
enabled/
Listen 443
<VirtualHost *:443>
LogLevel debug
ErrorLog /var/log/apache2/horizon.log
CustomLog /var/log/apache2/horizon_access.log combined
ServerAdmin controller
ServerName controller
ServerAlias controller
```
```bash
WSGIScriptAlias /horizon /usr/share/openstack-
dashboard/openstack_dashboard/wsgi/django.wsgi
WSGIDaemonProcess horizon user=www-data group=www-data processes=
threads=10 display-name=%{GROUP}
WSGIProcessGroup horizon
WSGIApplicationGroup %{GLOBAL}
Alias /horizon/static /var/lib/openstack-dashboard/static/
Alias /static /var/lib/openstack-dashboard/static/
<Directory /usr/share/openstack-dashboard/openstack_dashboard/wsgi>
Options All
AllowOverride All
Require all granted
</Directory>
```
```bash
<Directory /var/lib/openstack-dashboard/static>
Options All
AllowOverride All
Require all granted
</Directory>
SSLEngine on
SSLCipherSuite
ECDH+AESGCM:DH+AESGCM:ECDH+AES256:DH+AES256:ECDH+AES128:DH+AES:ECDH+3DES:DH+3DES:RSA
+AESGCM:RSA+AES:RSA+3DES:!aNULL:!MD5:!DSS:!RC
SSLCertificateKeyFile /etc/openstack-dashboard/key.pem
SSLCertificateFile /etc/openstack-dashboard/cert.pem
SSLCACertificateFile /etc/openstack-dashboard/ca.pem
</VirtualHost>
```

- Sửa cho Horizon kết nối tới địa chỉ HTTPS mới của Openstack:
    Không giống như các service khác, horizon không tự đăng nhập vào Openstack mà nhận thông
    tin người dùng nhập vào từ trang login (username, password) sau đó gửi thông tin này xác minh
    tới Keystone ở địa chỉ [http://localhost:5000/v](http://localhost:5000/v)
    -- Sửa địa chỉ nhận của Keystone bằng cách bổ xung thêm 1 region riêng nhận theo địa chỉ
    https.
```bash
docker cp ca.pem horizon_ssl:/etc/ssl/certs/ca-certificates.crt
docker cp django.wsgi horizon_ssl:/usr/share/openstack-dashboard/openstack_dashboard/wsgi/
import os
import sys
from django.core.wsgi import get_wsgi_application
```
# Add this file path to sys.path in order to import settings
```
sys.path.insert(0, os.path.normpath(os.path.join(
os.path.dirname(os.path.realpath(__file__)), '../..')))
os.environ['DJANGO_SETTINGS_MODULE'] = 'openstack_dashboard.settings'
sys.stdout = sys.stderr
sys.path.append("/usr/share/openstack-dashboard/")
DEBUG = True
application = get_wsgi_application()
docker cp settings.py horizon_ssl:/usr/share/openstack-dashboard/openstack_dashboard/
docker restart horizon

AVAILABLE_REGIONS = [
('http://localhost:5000/v3', 'local'),
('https://controller:5000/v3', 'remote') //Bổ xung thêm 1 region mới.
]

```
 Địa chỉ mới của horizon: https://controller/horizon (port 443)


### 2.3 Glance-API, Neutron-Server, Nova-api, Nova-placement_api

Các service này làm giống nhau là sử dụng Apache Module mod_proxy đứng ra làm gateways trung gian

chuyển tin.

https://httpd.apache.org/docs/2.4/mod/mod_proxy.html

- Apache HTTP Server có thể được cấu hình trong cả forward và reverse proxy mode.
- Một **forward proxy** được dùng khi client không thể truy cập trực tiếp tới server gốc (bị chặn) và
    phải truy cập thông qua forward proxy (fake ip ...vvv)
- Một **reverse proxy** xuất hiện trước mặt client như một web server, client không biết gì về server
    gốc và thực hiện request trực tiếp tới reverse proxy, reverse proxy sau đó sẽ lựa chọn địa điểm
    nhận request và chuyển tin tới.
- Sử dụng để internet user truy vấn tới server đứng sau firewall hoặc dùng cho load balance, đặt
    một số server vào một URL.
- Cấu hình:

Reverse Proxy

**ProxyPass** "/foo" "http://foo.example.com/bar"
**ProxyPassReverse** "/foo" "http://foo.example.com/bar"
Forward Proxy

**ProxyRequests** On
**ProxyVia** On

< **Proxy** "*">
**Require** host internal.example.com
</ **Proxy** >

- Trong đó:
- ProxyPass và ProxyPassReverse thực hiện map remote server tới local server


Ví dụ với Glance-Api

- Update danh sách trusted CA trong glance container:

**docker cp ca.pem glance:/etc/ssl/certs/ca-certificates.crt**

- Cài đặt apache httpd với mode SSL

```
yum -y install httpd mod_ssl
```
```
rm –rf /etc/httpd/conf.d/ssl.conf
sudo systemctl enable httpd.service
systemctl start httpd.service
```
- Bổ xung apache service làm https cho Glance-API
    ServerName controller
    local eth0 IP
    Listen 172.16.30.85: **9292**
    <VirtualHost 172.16.30.85:9292>
    same as ServerName above
    ServerName controller
    SSLEngine On
    SSLProtocol +SSLv3 +TLSv
    SSLCipherSuite
    HIGH:!RC4:!MD5:!aNULL:!eNULL:!EXP:!LOW:!MEDIUM
    SSLCACertificateFile
    /usr/share/docker/keystone/keystone/ssl/certs/ca.pem
    SSLCertificateFile
    /usr/share/docker/keystone/keystone/ssl/certs/cert.pem
    SSLCertificateKeyFile
    /usr/share/docker/keystone/keystone/ssl/certs/key.pem

```
# custom header for Paste SSLMiddleware
RequestHeader set X-Forwarded-Proto "https"
```
```
ProxyRequests off
ProxyPreserveHost off
ProxyPass / http://127.0.0.1: 9292 /
ProxyPassReverse / http://127.0.0.1: 9292 /
```
```
LogLevel warn
ErrorLog /apache2/glance/api_error.log
CustomLog /apache2/glance/api_access.log combined
</VirtualHost>
```

- Service này sẽ chuyển các request tới https://controller:9292 và [http://localhost:](http://localhost:)
- Sửa các service gốc bao vào localhost thay vì Ip controller:

```
Glance bind_host = localhost
bind_port = 9292
registry_host = localhost
Nova-api [DEFAULT]
my_ip = localhost
enabled_apis=osapi_compute,metadata
osapi_compute_listen = localhost
osapi_compute_listen_port = 8774
metadata_listen = localhost
metadata_listen_port = 8775
[glance]
api_servers = https://controller:
[neutron]
url = https://controller:
auth_url = https://controller:5000/v
Nova-placement-
api
```
```
vim /etc/apache2/sites-enabled/nova-placement-api.conf
Listen 127.0.0.1:
<VirtualHost 127.0.0.1:8778>
</VirtualHost>
```
```
Neutron bind_host = localhost
bind_port = 9696
```
- Trên compute Node:

```
Sửa file nova.conf và neutron.conf sửa hết http về https
Đồng thời trên các compute Node bổ xung ca.pem vào list trusted CA
```

### 2.4 Nova metadata service và Nova Novnc Proxy

Làm tương tự với Glance-API là bổ xung file apache.conf vào thư mục /etc/httpd/conf.d

Tuy nhiên trên các Compute Node cần bổ xung cấu hình để sử dụng địa chỉ https này:

```
/etc/httpd/conf.d/nova_metadata.conf
ServerName controller
```
```
# local eth0 IP
Listen 172.16.30.85:
```
```
<VirtualHost 172.16.30.85:8775>
# same as ServerName above
ServerName controller
```
```
SSLEngine On
SSLProtocol +SSLv3 +TLSv
SSLCipherSuite
HIGH:!RC4:!MD5:!aNULL:!eNULL:!EXP:!LOW:!MEDIUM
SSLCACertificateFile
/usr/share/docker/keystone/keystone/ssl/certs/ca.pem
SSLCertificateFile
/usr/share/docker/keystone/keystone/ssl/certs/cert.pem
SSLCertificateKeyFile
/usr/share/docker/keystone/keystone/ssl/certs/key.pem
```
```
# custom header for Paste SSLMiddleware
RequestHeader set X-Forwarded-Proto "https"
```
```
ProxyRequests off
ProxyPreserveHost off
ProxyPass / http://127.0.0.1:8775/
ProxyPassReverse / http://127.0.0.1:8775/
```
```
LogLevel warn
ErrorLog /apache2/nova/nova_metadata_error.log
CustomLog /apache2/nova/nova_metadata_access.log combined
</VirtualHost>
/etc/nova/nova.conf
[vnc]
enabled = true
server_listen = $my_ip
server_proxyclient_address = $my_ip
novncproxy_base_url = https://controller:6080/vnc_auto.html
/usr/share/docker/neutron/neutron/metadata_agent.ini
[DEFAULT]
nova_metadata_host = controller
metadata_proxy_shared_secret = I8IZc2GMAYbTfkgi8R7xqw3RSoxfwZ0S
nova_metadata_port = 8775
nova_metadata_protocol = https
DHCP và Openvswitch agent không cần sửa gì vì tự tìm được địa chỉ https neutron thông qua
keystone endpoints
```

