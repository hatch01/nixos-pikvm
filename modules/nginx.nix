{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.kvmd;
in

{
  options.services.kvmd.nginx = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable nginx web server for PiKVM";
    };

    httpPort = mkOption {
      type = types.port;
      default = 80;
      description = "HTTP port for nginx";
    };

    httpsPort = mkOption {
      type = types.port;
      default = 443;
      description = "HTTPS port for nginx";
    };

    httpsEnabled = mkOption {
      type = types.bool;
      default = true;
      description = "Enable HTTPS support";
    };
  };

  config = mkIf (cfg.enable && cfg.nginx.enable) {
    # Add nginx user to kvmd groups for socket access
    users.users.nginx.extraGroups = [ "kvmd" "kvmd-janus" "kvmd-media" ];

    services.nginx = {
      enable = true;

      appendConfig = ''
        worker_processes 4;
      '';

      eventsConfig = ''
        worker_connections 1024;
        use epoll;
        multi_accept on;
      '';

      upstreams = {
        "kvmd" = {
          servers = {
            "unix:/run/kvmd/kvmd.sock" = { };
          };
        };
        "ustreamer" = {
          servers = {
            "unix:/run/ustreamer/ustreamer.sock" = { };
          };
        };
        "janus-ws" = {
          servers = {
            "unix:/run/janus/janus.sock" = { };
          };
        };
        "media" = {
          servers = {
            "unix:/run/kvmd/media.sock" = { };
          };
        };
      };

      virtualHosts = {
        "default" = {
          default = true;
          # addSSL = cfg.nginx.httpsEnabled;



          # sslCertificate = mkIf cfg.nginx.httpsEnabled "/etc/kvmd/nginx/ssl/server.crt";
          # sslCertificateKey = mkIf cfg.nginx.httpsEnabled "/etc/kvmd/nginx/ssl/server.key";

          extraConfig = ''
            absolute_redirect off;
            auth_request /auth_check;
          '';

          locations = {
            "= /auth_check" = {
              extraConfig = ''
                internal;
                proxy_pass http://kvmd/auth/check;
                proxy_pass_request_body off;
                proxy_set_header Content-Length "";
                auth_request off;
              '';
            };

            "/" = {
              root = "${cfg.package}/share/kvmd/web";
              index = "index.html";
              extraConfig = ''
                error_page 401 = @login;
                add_header Cache-Control "no-store, no-cache, must-revalidate";
                expires -1;
              '';
            };

            "@login" = {
              extraConfig = "return 302 /login;";
            };

            "/login" = {
              root = "${cfg.package}/share/kvmd/web";
              extraConfig = "auth_request off;";
            };

            "/share" = {
              root = "${cfg.package}/share/kvmd/web";
              extraConfig = ''
                auth_request off;
                add_header Cache-Control "no-store, no-cache, must-revalidate";
                expires -1;
              '';
            };

            "= /share/css/user.css" = {
              alias = "/etc/kvmd/web.css";
              extraConfig = "auth_request off;";
            };

            "= /favicon.ico" = {
              alias = "${cfg.package}/share/kvmd/web/favicon.ico";
              extraConfig = ''
                auth_request off;
                add_header Cache-Control "no-store, no-cache, must-revalidate";
                expires -1;
              '';
            };

            "= /robots.txt" = {
              alias = "${cfg.package}/share/kvmd/web/robots.txt";
              extraConfig = ''
                auth_request off;
                add_header Cache-Control "no-store, no-cache, must-revalidate";
                expires -1;
              '';
            };

            "/api/ws" = {
              proxyPass = "http://kvmd";
              proxyWebsockets = true;
              extraConfig = ''
                rewrite ^/api/ws$ /ws break;
                rewrite ^/api/ws\?(.*)$ /ws?$1 break;
                auth_request off;
              '';
            };

            "/api/hid/print" = {
              proxyPass = "http://kvmd";
              extraConfig = ''
                rewrite ^/api/hid/print$ /hid/print break;
                rewrite ^/api/hid/print\?(.*)$ /hid/print?$1 break;
                client_max_body_size 100M;
                auth_request off;
              '';
            };

            "/api/msd/read" = {
              proxyPass = "http://kvmd";
              extraConfig = ''
                rewrite ^/api/msd/read$ /msd/read break;
                rewrite ^/api/msd/read\?(.*)$ /msd/read?$1 break;
                proxy_buffering off;
                proxy_read_timeout 7d;
                auth_request off;
              '';
            };

            "/api/msd/write_remote" = {
              proxyPass = "http://kvmd";
              extraConfig = ''
                rewrite ^/api/msd/write_remote$ /msd/write_remote break;
                rewrite ^/api/msd/write_remote\?(.*)$ /msd/write_remote?$1 break;
                proxy_buffering off;
                proxy_read_timeout 7d;
                auth_request off;
              '';
            };

            "/api/msd/write" = {
              proxyPass = "http://kvmd";
              extraConfig = ''
                rewrite ^/api/msd/write$ /msd/write break;
                rewrite ^/api/msd/write\?(.*)$ /msd/write?$1 break;
                client_max_body_size 100M;
                auth_request off;
              '';
            };

            "/api/log" = {
              proxyPass = "http://kvmd";
              extraConfig = ''
                rewrite ^/api/log$ /log break;
                rewrite ^/api/log\?(.*)$ /log?$1 break;
                proxy_buffering off;
                proxy_read_timeout 7d;
                auth_request off;
              '';
            };

            "/api" = {
              proxyPass = "http://kvmd";
              extraConfig = ''
                rewrite ^/api$ / break;
                rewrite ^/api/(.*)$ /$1 break;
                auth_request off;
              '';
            };

            "/streamer" = {
              proxyPass = "http://ustreamer";
              extraConfig = ''
                rewrite ^/streamer$ / break;
                rewrite ^/streamer\?(.*)$ ?$1 break;
                rewrite ^/streamer/(.*)$ /$1 break;
                proxy_buffering off;
              '';
            };

            "/redfish" = {
              proxyPass = "http://kvmd";
              extraConfig = "auth_request off;";
            };

            "/janus/ws" = {
              proxyPass = "http://janus-ws";
              proxyWebsockets = true;
              extraConfig = ''
                rewrite ^/janus/ws$ / break;
                rewrite ^/janus/ws\?(.*)$ /?$1 break;
              '';
            };

            "= /share/js/kvm/janus.js" = {
              alias = "${pkgs.janus-gateway}/share/janus/javascript/janus.js";
              extraConfig = ''
                add_header Cache-Control "no-store, no-cache, must-revalidate";
                expires -1;
              '';
            };

            "= /share/js/kvm/adapter.js" = {
              alias = "${pkgs.janus-gateway}/share/janus/javascript/adapter.js";
              extraConfig = ''
                add_header Cache-Control "no-store, no-cache, must-revalidate";
                expires -1;
              '';
            };

            "/api/media/ws" = {
              proxyPass = "http://media";
              proxyWebsockets = true;
              extraConfig = ''
                rewrite ^/api/media/ws$ /ws break;
                rewrite ^/api/media/ws\?(.*)$ /ws?$1 break;
              '';
            };
          };
        };
      };
    };

    # Generate self-signed certificate if HTTPS is enabled
    # systemd.services.pikvm-nginx-ssl = mkIf cfg.nginx.httpsEnabled {
    #   description = "Generate PiKVM nginx SSL certificate";
    #   wantedBy = [ "nginx.service" ];
    #   after = [ "systemd-tmpfiles-setup.service" ];
    #   before = [ "nginx.service" ];
    #   serviceConfig = {
    #     Type = "oneshot";
    #     RemainAfterExit = true;
    #     ExecStart = pkgs.writeScript "generate-ssl-cert" ''
    #       #!${pkgs.bash}/bin/bash
    #       mkdir -p /etc/kvmd/nginx/ssl
    #       if [ ! -f /etc/kvmd/nginx/ssl/server.crt ] || [ ! -f /etc/kvmd/nginx/ssl/server.key ]; then
    #         ${pkgs.openssl}/bin/openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    #           -keyout /etc/kvmd/nginx/ssl/server.key \
    #           -out /etc/kvmd/nginx/ssl/server.crt \
    #           -subj "/C=US/ST=State/L=City/O=Organization/OU=OrgUnit/CN=pikvm"
    #         chmod 600 /etc/kvmd/nginx/ssl/server.key
    #         chmod 644 /etc/kvmd/nginx/ssl/server.crt
    #       fi
    #     '';
    #   };
    # };

    # Basic CSS file
    environment.etc."kvmd/web.css".text = ''
      /* Custom PiKVM CSS */
      body {
        font-family: monospace;
      }

    '';

    # Create necessary directories and fix socket permissions
    systemd.tmpfiles.rules = [
      "d /etc/kvmd 0755 root root -"
      "d /etc/kvmd/nginx 0755 root root -"
      "d /etc/kvmd/nginx/ssl 0755 root root -"
      "d /tmp/kvmd-nginx 0755 nginx nginx -"
      "d /tmp/kvmd-nginx/client_body_temp 0755 nginx nginx -"
      "d /tmp/kvmd-nginx/fastcgi_temp 0755 nginx nginx -"
      "d /tmp/kvmd-nginx/proxy_temp 0755 nginx nginx -"
      "d /tmp/kvmd-nginx/scgi_temp 0755 nginx nginx -"
      "d /tmp/kvmd-nginx/uwsgi_temp 0755 nginx nginx -"
      # Ensure socket directories have proper permissions for nginx access
      "d /run/kvmd 0775 kvmd kvmd -"
      "d /run/ustreamer 0775 root kvmd -"
      "d /run/janus 0775 kvmd-janus kvmd-janus -"
    ];
  };
}
