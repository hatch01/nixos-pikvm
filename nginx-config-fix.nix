# Replace your services.nginx block with this configuration
# This adapts the nginx config to use TCP ports instead of Unix socket

services.nginx = {
  enable = true;
  config = ''
    worker_processes 4;
    
    error_log stderr;
    
    events {
      worker_connections 1024;
      use epoll;
      multi_accept on;
    }
    
    http {
      types_hash_max_size 4096;
      server_names_hash_bucket_size 128;
      
      access_log off;
      
      include ${pkgs.nginx}/conf/mime.types;
      default_type application/octet-stream;
      charset utf-8;
      
      sendfile on;
      tcp_nodelay on;
      tcp_nopush on;
      keepalive_timeout 10;
      client_max_body_size 4k;
      
      client_body_temp_path   /tmp/kvmd-nginx/client_body_temp;
      fastcgi_temp_path       /tmp/kvmd-nginx/fastcgi_temp;
      proxy_temp_path         /tmp/kvmd-nginx/proxy_temp;
      scgi_temp_path          /tmp/kvmd-nginx/scgi_temp;
      uwsgi_temp_path         /tmp/kvmd-nginx/uwsgi_temp;
      
      upstream kvmd {
        server 127.0.0.1:8080;
      }
      
      server {
        listen 80;
        
        location / {
          proxy_pass http://kvmd;
          proxy_http_version 1.1;
          proxy_set_header Upgrade $http_upgrade;
          proxy_set_header Connection "upgrade";
          proxy_set_header Host $host;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto $scheme;
        }
      }
    }
  '';
};

# Keep the temp directories creation
systemd.tmpfiles.rules = [
  "d /tmp/kvmd-nginx 0755 nginx nginx -"
  "d /tmp/kvmd-nginx/client_body_temp 0755 nginx nginx -"
  "d /tmp/kvmd-nginx/fastcgi_temp 0755 nginx nginx -"
  "d /tmp/kvmd-nginx/proxy_temp 0755 nginx nginx -"
  "d /tmp/kvmd-nginx/scgi_temp 0755 nginx nginx -"
  "d /tmp/kvmd-nginx/uwsgi_temp 0755 nginx nginx -"
];