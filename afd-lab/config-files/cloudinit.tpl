#cloud-config
packages:
  - nginx
write_files:
  - owner: root:root
    append: 0
    path: /etc/nginx/sites-available/afd.conf
    content: |
      server {
          listen 80 default_server;
          listen [::]:80 default_server;
          root /var/www/html;
          index index.html index.htm index.nginx-debian.html;
          server_name _;
          location / {
                  try_files $uri $uri/ =404;
          }
          location /nginx_status {
            stub_status;
          }
runcmd:
  - ln -s /etc/nginx/sites-available/afd.conf /etc/nginx/sites-enabled/afd.conf
  - rm -rf /etc/nginx/sites-enabled/default
  - sudo systemctl enable --now nginx
  - sudo systemctl reload nginx