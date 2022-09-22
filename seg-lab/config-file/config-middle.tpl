#cloud-config
packages:
  - nginx
  - append: true
    path: /etc/nginx/sites-available/rp.conf
    content: |
      server {
        #We listen for HTTP requests on port 80, using servername to know which site to server
        #Server name is part of the Host header, Server Name Indication
        listen 80 default_server;

        location / {
          proxy_http_version 1.1;
          #We limit method to only required one
          limit_except GET {
            deny all;
          }
          proxy_pass https://apion-lg.s3.eu-west-2.amazonaws.com/LG.png;
        }
      }
runcmd:
  - ln -s /etc/nginx/sites-available/rp.conf /etc/nginx/sites-enabled/rp.conf
  - rm -rf /etc/ngnix/sites-enabled/default
  - systemctl enable --now nginx
  - systemctl restart nginx