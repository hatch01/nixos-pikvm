{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.kvmd;
in {
  options.services.kvmd = {
    enable = mkEnableOption "PiKVM daemon (KVM over IP)";

    package = mkOption {
      type = types.package;
      default = pkgs.kvmd;
      defaultText = literalExpression "pkgs.kvmd";
      description = "The kvmd package to use.";
    };

    withTesseract = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to enable OCR support using tesseract.";
    };

    hostName = mkOption {
      type = types.str;
      default = "pikvm";
      description = "Hostname for the PiKVM device.";
    };

    nginx = {
      enable = mkEnableOption "NGINX for PiKVM web interface";

      sslCertificate = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Path to SSL certificate for NGINX.";
      };

      sslCertificateKey = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Path to SSL certificate key for NGINX.";
      };
    };
  };

  config = mkIf cfg.enable {
    # Ensure the kvmd package is included with desired options
    environment.systemPackages = [
      (cfg.package.override {withTesseract = cfg.withTesseract;})
    ];

    # Create required users and groups
    users.groups.kvmd = {};

    users.users.kvmd = {
      description = "KVM over IP daemon user";
      group = "kvmd";
      isSystemUser = true;
    };

    # Configure system for PiKVM
    networking.hostName = cfg.hostName;

    # Create necessary directories
    systemd.tmpfiles.rules = [
      "d /var/lib/kvmd 0755 kvmd kvmd -"
      "d /var/lib/kvmd/msd 0755 kvmd kvmd -"
      "d /var/lib/kvmd/pst 1775 kvmd kvmd -"
      "d /etc/kvmd 0755 root root -"
      "d /etc/kvmd/nginx 0755 root root -"
      "d /etc/kvmd/nginx/ssl 0755 root root -"
      "d /etc/kvmd/override.d 0755 root root -"
    ];

    # Main kvmd service
    systemd.services.kvmd = {
      description = "PiKVM daemon";
      wantedBy = ["multi-user.target"];
      after = ["network.target"];

      serviceConfig = {
        Type = "simple";
        User = "kvmd";
        Group = "kvmd";
        ExecStart = "${cfg.package}/bin/kvmd";
        Restart = "on-failure";
        RestartSec = "3";
      };
    };

    # NGINX configuration for the web interface
    services.nginx = mkIf cfg.nginx.enable {
      enable = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;

      # Basic configuration for kvmd
      virtualHosts."${cfg.hostName}" = {
        enableACME = cfg.nginx.sslCertificate == null && cfg.nginx.sslCertificateKey == null;
        forceSSL = true;

        # Use provided certificates if available
        sslCertificate = cfg.nginx.sslCertificate;
        sslCertificateKey = cfg.nginx.sslCertificateKey;

        locations."/" = {
          proxyPass = "http://localhost:8080";
          proxyWebsockets = true;
        };
      };
    };

    # Optional: Configure ustreamer if used with PiKVM
    systemd.services.ustreamer = {
      description = "µStreamer for PiKVM";
      wantedBy = ["multi-user.target"];
      after = ["network.target"];

      serviceConfig = {
        Type = "simple";
        User = "kvmd";
        Group = "kvmd";
        ExecStart = "${pkgs.ustreamer}/bin/ustreamer --host 127.0.0.1 --port 8081";
        Restart = "on-failure";
        RestartSec = "3";
      };
    };
  };
}
