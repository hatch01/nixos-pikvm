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
  };

  config = mkIf cfg.enable {
    # Create required users and groups
    users.groups.kvmd = {};

    users.users.kvmd = {
      description = "KVM over IP daemon user";
      group = "kvmd";
      isSystemUser = true;
    };

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
        ExecStart = "${lib.getExe (cfg.package.override {withTesseract = cfg.withTesseract;})}";
        Restart = "on-failure";
        RestartSec = "3";
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
