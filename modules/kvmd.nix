{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
with lib;
let
  cfg = config.services.kvmd;
in
{
  imports = [
    inputs.nixos-hardware.nixosModules.raspberry-pi-4
  ];

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
    users.groups.kvmd = { };
    users.groups.kvmd-ipmi = { };
    users.groups.kvmd-janus = { };
    users.groups.kvmd-localhid = { };
    users.groups.kvmd-media = { };
    users.groups.kvmd-pst = { };
    users.groups.kvmd-vnc = { };
    users.groups.gpio = { };

    users.users.kvmd = {
      description = "KVM over IP daemon user";
      group = "kvmd";
      isSystemUser = true;
      extraGroups = [
        "gpio"
        "video"
        "input"
        "tty"
      ];
    };
    users.users.kvmd-ipmi = {
      description = "KVMD IPMI user";
      group = "kvmd-ipmi";
      isSystemUser = true;
    };
    users.users.kvmd-janus = {
      description = "KVMD Janus user";
      group = "kvmd-janus";
      isSystemUser = true;
    };
    users.users.kvmd-localhid = {
      description = "KVMD Local HID user";
      group = "kvmd-localhid";
      isSystemUser = true;
    };
    users.users.kvmd-media = {
      description = "KVMD Media user";
      group = "kvmd-media";
      isSystemUser = true;
    };
    users.users.kvmd-pst = {
      description = "KVMD Persistent Storage user";
      group = "kvmd-pst";
      isSystemUser = true;
    };
    users.users.kvmd-vnc = {
      description = "KVMD VNC user";
      group = "kvmd-vnc";
      isSystemUser = true;
    };

    # Create necessary directories
    systemd.tmpfiles.rules = [
      "d /run/kvmd 0755 kvmd kvmd -"
      "d /run/kvmd/otg 0755 kvmd kvmd -"
      "d /var/lib/kvmd 0755 kvmd kvmd -"
      "d /var/lib/kvmd/msd 0755 kvmd kvmd -"
      "d /var/lib/kvmd/pst 1775 kvmd-pst kvmd-pst -"
      "d /etc/kvmd 0755 root root -"
      "d /etc/kvmd/nginx 0755 root root -"
      "d /etc/kvmd/nginx/ssl 0755 root root -"
      "d /etc/kvmd/override.d 0755 root root -"
    ];

    # Patch: generate /etc/kvmd/main.yaml with correct extras, platform, vcgencmd_cmd, keymap, streamer, and pst/remount_cmd paths
    # environment.etc."kvmd/main.yaml".text = ''
    #   kvmd:
    #     info:
    #       extras: "${cfg.package}/lib/python3.12/site-packages/kvmd/apps/kvmd/info"
    #       hw:
    #         platform: "/etc/kvmd/platform"
    #         vcgencmd_cmd: ["${pkgs.libraspberrypi}/bin/vcgencmd"]
    #     hid:
    #       keymap: "${cfg.package}/share/kvmd/keymaps/en-us"
    #     streamer:
    #       pre_start_cmd: ["${pkgs.coreutils}/bin/true", "pre-start"]
    #       cmd: ["${pkgs.ustreamer}/bin/ustreamer", "--device=/dev/kvmd-video", "--persistent", "--dv-timings", "--format=uyvy", "--buffers=6", "--encoder=m2m-image", "--workers=3", "--quality={quality}", "--desired-fps={desired_fps}", "--drop-same-frames=30", "--unix={unix}", "--unix-rm", "--unix-mode=0660", "--exit-on-parent-death", "--process-name-prefix={process_name_prefix}", "--notify-parent", "--no-log-colors", "--jpeg-sink=kvmd::ustreamer::jpeg", "--jpeg-sink-mode=0660", "--h264-sink=kvmd::ustreamer::h264", "--h264-sink-mode=0660", "--h264-bitrate={h264_bitrate}", "--h264-gop={h264_gop}"]
    #   pst:
    #     remount_cmd: ["${pkgs.sudo}/bin/sudo", "--non-interactive", "${cfg.package}/bin/kvmd-helper-pst-remount", "{mode}"]
    # '';
    # Create an empty /etc/kvmd/platform file
    # environment.etc."kvmd/platform".text = "";

    hardware.raspberry-pi."4" = {
      tc358743.enable = true;
      dwc2 = {
          enable = true;
          dr_mode = "peripheral";
      };
      apply-overlays-dtmerge.enable = true;
    };
    hardware.deviceTree = {
      filter = lib.mkForce "bcm2711-rpi-4-b.dtb";
    };

    hardware.i2c.enable = true;

    # Main kvmd service
    systemd.services.kvmd = {
      description = "PiKVM daemon";
      wantedBy = [ "multi-user.target" ];
      after = [
        "network.target"
        "kvmd-otg.service"
      ];

      serviceConfig = {
        Type = "simple";
        User = "kvmd";
        Group = "kvmd";
        ExecStart = "${lib.getExe (cfg.package.override { withTesseract = cfg.withTesseract; })} --run";
        Restart = "on-failure";
        RestartSec = "3";
      };
    };
    systemd.services.kvmd-ipmi = {
      description = "PiKVM - IPMI to KVMD proxy";
      after = [ "kvmd.service" ];
      serviceConfig = {
        User = "kvmd-ipmi";
        Group = "kvmd-ipmi";
        Type = "simple";
        Restart = "always";
        RestartSec = 3;
        AmbientCapabilities = "CAP_NET_BIND_SERVICE";
        ExecStart = "${lib.getBin cfg.package}/bin/kvmd-ipmi --run";
        TimeoutStopSec = 3;
      };
      wantedBy = [ "multi-user.target" ];
    };

    # systemd.services.kvmd-janus = {
    #   description = "PiKVM - Janus WebRTC Gateway";
    #   after = ["network.target" "network-online.target" "nss-lookup.target" "kvmd.service"];
    #   wants = ["network-online.target"];
    #   serviceConfig = {
    #     User = "kvmd-janus";
    #     Group = "kvmd-janus";
    #     Type = "simple";
    #     Restart = "always";
    #     RestartSec = 3;
    #     AmbientCapabilities = "CAP_NET_RAW";
    #     LimitNOFILE = 65536;
    #     UMask = "0117";
    #     ExecStart = "${lib.getBin cfg.package}/bin/kvmd-janus --run";
    #     TimeoutStopSec = 10;
    #     KillMode = "mixed";
    #   };
    #   wantedBy = ["multi-user.target"];
    # };

    systemd.services.kvmd-janus = {
      description = "PiKVM - Janus WebRTC Gateway";
      after = [
        "network.target"
        "network-online.target"
        "nss-lookup.target"
        "kvmd.service"
      ];
      wants = [ "network-online.target" ];
      serviceConfig = {
        User = "kvmd-janus";
        Group = "kvmd-janus";
        Type = "simple";
        Restart = "always";
        RestartSec = 3;
        AmbientCapabilities = "CAP_NET_RAW";
        LimitNOFILE = 65536;
        UMask = "0117";
        ExecStart = "${pkgs.janus-gateway}/bin/janus --disable-colors --plugins-folder=${pkgs.ustreamer}/lib/ustreamer/janus --configs-folder=/etc/kvmd/janus";
        TimeoutStopSec = 10;
        KillMode = "mixed";
      };
      wantedBy = [ "multi-user.target" ];
    };

    systemd.services.kvmd-media = {
      description = "PiKVM - Media proxy server";
      after = [ "kvmd.service" ];
      serviceConfig = {
        User = "kvmd-media";
        Group = "kvmd-media";
        Type = "simple";
        Restart = "always";
        RestartSec = 3;
        ExecStart = "${lib.getBin cfg.package}/bin/kvmd-media --run";
        TimeoutStopSec = 3;
      };
      wantedBy = [ "multi-user.target" ];
    };

    systemd.services.kvmd-oled = {
      description = "PiKVM - A small OLED daemon";
      after = [ "systemd-modules-load.service" ];
      unitConfig = {
        ConditionPathExists = "/dev/i2c-1";
      };
      serviceConfig = {
        Type = "simple";
        Restart = "always";
        RestartSec = "3";
        ExecStartPre = "${lib.getBin cfg.package}/bin/kvmd-oled --interval=3 --clear-on-exit --image=@hello.ppm";
        ExecStart = "${lib.getBin cfg.package}/bin/kvmd-oled";
        TimeoutStopSec = 3;
      };
      wantedBy = [ "multi-user.target" ];
    };

    systemd.services.kvmd-oled-reboot = {
      description = "PiKVM - Display reboot message on the OLED";
      unitConfig = {
        DefaultDependencies = false;
      };
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "/bin/bash -c 'kill -USR1 `systemctl show -P MainPID kvmd-oled`'";
        ExecStop = "/bin/true";
        RemainAfterExit = true;
      };
      wantedBy = [ "reboot.target" ];
    };

    systemd.services.kvmd-oled-shutdown = {
      description = "PiKVM - Display shutdown message on the OLED";
      unitConfig = {
        Conflicts = "reboot.target";
        Before = [
          "shutdown.target"
          "poweroff.target"
          "halt.target"
        ];
        DefaultDependencies = false;
      };
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "/bin/bash -c 'kill -USR2 `systemctl show -P MainPID kvmd-oled`'";
        ExecStop = "/bin/true";
        RemainAfterExit = true;
      };
      wantedBy = [ "shutdown.target" ];
    };

    systemd.services.kvmd-otgnet = {
      description = "PiKVM - OTG network service";
      after = [
        "kvmd-otg.service"
        "network-pre.target"
      ];
      wants = [ "network-pre.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${lib.getBin cfg.package}/bin/kvmd-otgnet start";
        ExecStop = "${lib.getBin cfg.package}/bin/kvmd-otgnet stop";
        RemainAfterExit = true;
      };
      wantedBy = [ "multi-user.target" ];
    };

    systemd.services.kvmd-otg = {
      description = "PiKVM - OTG setup";
      after = [
        "kvmd-msd-image.service"
        "systemd-modules-load.service"
      ];
      before = [ "kvmd.service" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${lib.getBin cfg.package}/bin/kvmd-otg start";
        ExecStop = "${lib.getBin cfg.package}/bin/kvmd-otg stop";
        RemainAfterExit = true;
      };
      wantedBy = [ "multi-user.target" ];
    };

    systemd.services.kvmd-pst = {
      description = "PiKVM - The KVMD persistent storage manager";
      before = [ "kvmd.service" ];
      serviceConfig = {
        User = "kvmd-pst";
        Group = "kvmd-pst";
        Type = "simple";
        Restart = "always";
        RestartSec = "3";
        ExecStart = "${lib.getBin cfg.package}/bin/kvmd-pst --run";
        TimeoutStopSec = 5;
      };
      wantedBy = [ "multi-user.target" ];
    };

    systemd.services.kvmd-tc358743 = {
      description = "PiKVM - EDID loader for TC358743";
      wants = [ "dev-kvmd\\x2dvideo.device" ];
      after = [
        "dev-kvmd\\x2dvideo.device"
        "systemd-modules-load.service"
      ];
      before = [ "kvmd.service" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.v4l-utils}/bin/v4l2-ctl --device=/dev/video0 --set-edid=file=/etc/kvmd/tc358743-edid.hex --info-edid";
        ExecStop = "${pkgs.v4l-utils}/bin/v4l2-ctl --device=/dev/video0 --clear-edid";
        RemainAfterExit = true;
      };
      wantedBy = [ "multi-user.target" ];
    };

    systemd.services.kvmd-vnc = {
      description = "PiKVM - VNC to KVMD/Streamer proxy";
      after = [ "kvmd.service" ];
      serviceConfig = {
        User = "kvmd-vnc";
        Group = "kvmd-vnc";
        Type = "simple";
        Restart = "always";
        RestartSec = "3";
        ExecStart = "${lib.getBin cfg.package}/bin/kvmd-vnc --run";
        TimeoutStopSec = 3;
      };
      wantedBy = [ "multi-user.target" ];
    };

    systemd.services.kvmd-watchdog = {
      description = "PiKVM - RTC-based hardware watchdog";
      after = [ "systemd-modules-load.service" ];
      serviceConfig = {
        Type = "simple";
        Restart = "always";
        RestartSec = "3";
        ExecStart = "${lib.getBin cfg.package}/bin/kvmd-watchdog run";
        TimeoutStopSec = 3;
      };
      wantedBy = [ "multi-user.target" ];
    };

    # Configure sudo permissions for kvmd users
    security.sudo = {
      enable = true;
      extraRules = [
        {
          users = [ "kvmd" ];
          commands = [
            {
              command = "${cfg.package}/bin/kvmd-helper-otgmsd-remount *";
              options = [ "NOPASSWD" ];
            }
            {
              command = "${cfg.package}/bin/kvmd-helper-pst-remount *";
              options = [ "NOPASSWD" ];
            }
          ];
        }
        {
          users = [ "kvmd-pst" ];
          commands = [
            {
              command = "${cfg.package}/bin/kvmd-helper-pst-remount *";
              options = [ "NOPASSWD" ];
            }
          ];
        }
      ];
    };

    # Ensure /dev/gpiochip* nodes are accessible to kvmd (try both possible subsystems)
    services.udev.extraRules = ''
      KERNEL=="gpiochip*", SUBSYSTEM=="gpio", GROUP="gpio", MODE="0660"
      KERNEL=="gpiochip*", SUBSYSTEM=="misc", GROUP="gpio", MODE="0660"
      KERNEL=="vchiq|vcsm|vcio", GROUP="video", MODE="0660"

      # Here are described some bindings for PiKVM devices.
      # Do not edit this file.

      ACTION!="remove", KERNEL=="ttyACM[0-9]*", SUBSYSTEM=="tty", SUBSYSTEMS=="usb", ATTRS{idVendor}=="1209", ATTRS{idProduct}=="eda3", SYMLINK+="kvmd-hid-bridge"
      ACTION!="remove", KERNEL=="ttyACM[0-9]*", SUBSYSTEM=="tty", SUBSYSTEMS=="usb", ATTRS{idVendor}=="2e8a", ATTRS{idProduct}=="1080", SYMLINK+="kvmd-switch"

      # Disable USB autosuspend for critical devices
      ACTION!="remove", SUBSYSTEM=="usb", ATTR{idVendor}=="1209", ATTR{idProduct}=="eda3", GOTO="kvmd-usb"
      ACTION!="remove", SUBSYSTEM=="usb", ATTR{idVendor}=="2e8a", ATTR{idProduct}=="1080", GOTO="kvmd-usb"
      GOTO="end"

      LABEL="kvmd-usb"
      ATTR{power/control}="on", ATTR{power/autosuspend_delay_ms}="-1"

      LABEL="end"
      # https://unix.stackexchange.com/questions/66901/how-to-bind-usb-device-under-a-static-name
      # https://wiki.archlinux.org/index.php/Udev#Setting_static_device_names
      KERNEL=="video[0-9]*", SUBSYSTEM=="video4linux", KERNELS=="fe801000.csi|fe801000.csi1", ATTR{name}=="unicam-image", GROUP="kvmd", SYMLINK+="kvmd-video", TAG+="systemd"
      KERNEL=="hidg0", GROUP="kvmd", SYMLINK+="kvmd-hid-keyboard"
      KERNEL=="hidg1", GROUP="kvmd", SYMLINK+="kvmd-hid-mouse"
      KERNEL=="hidg2", GROUP="kvmd", SYMLINK+="kvmd-hid-mouse-alt"
    '';

    # Update the fstab entry for /var/lib/kvmd/msd to include x-systemd.requires
    fileSystems."/var/lib/kvmd/msd" = {
      device = "LABEL=PIMSD";
      fsType = "ext4";
      options = [
        "nodev"
        "nosuid"
        "noexec"
        "ro"
        "errors=remount-ro"
        "X-kvmd.otgmsd-user=kvmd"
      ];
      neededForBoot = false;
    };

    fileSystems."/var/lib/kvmd/pst" = {
      device = "LABEL=PIPST";
      fsType = "ext4";
      options = [
        "nodev"
        "nosuid"
        "noexec"
        "ro"
        "errors=remount-ro"
        "X-kvmd.pst-user=kvmd-pst"
      ];
      neededForBoot = false;
    };

    # Add system.activationScripts to create and set proper permissions for helper scripts
    # system.activationScripts.kvmd-helper-scripts = ''
    #   # Create symlinks to the helper scripts in /run/wrappers/bin
    #   # This allows the scripts to be found in the same location as sudo
    #   mkdir -p /run/wrappers/bin
    #   ln -sf ${cfg.package}/bin/kvmd-helper-otgmsd-remount /run/wrappers/bin/
    #   ln -sf ${cfg.package}/bin/kvmd-helper-pst-remount /run/wrappers/bin/

    #   # Ensure the helper scripts are executable and have proper permissions
    #   if [ -f ${cfg.package}/bin/kvmd-helper-otgmsd-remount ]; then
    #     chmod 755 ${cfg.package}/bin/kvmd-helper-otgmsd-remount
    #   fi
    #   if [ -f ${cfg.package}/bin/kvmd-helper-pst-remount ]; then
    #     chmod 755 ${cfg.package}/bin/kvmd-helper-pst-remount
    #   fi
    # '';

    # Add a systemd service to ensure the file exists before mounting
    systemd.services.kvmd-msd-image = {
      description = "Ensure MSD image exists for PiKVM";
      before = [ "var-lib-kvmd-msd.mount" ];
      wantedBy = [ "var-lib-kvmd-msd.mount" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "kvmd-msd-image-setup" ''
          set -e
          IMAGE=/var/lib/kvmd/msd.img
          SIZE=128M
          LOOPDEV=/dev/loop1
          # Create image if missing
          if [ ! -f "$IMAGE" ]; then
            dd if=/dev/zero of="$IMAGE" bs=1M count=128
            mkfs.vfat "$IMAGE"
          fi
          # Detach loop device if already associated
          if ${pkgs.util-linux}/bin/losetup -j "$IMAGE" | grep -q "$LOOPDEV"; then
            ${pkgs.util-linux}/bin/losetup -d "$LOOPDEV"
          fi
          # Set up loop device
          ${pkgs.util-linux}/bin/losetup "$LOOPDEV" "$IMAGE" || true
        '';
      };
    };

    boot.kernelModules = [
      "configfs"
      "dwc2"
      "libcomposite"
      "tc358743"
      "rtc_cmos"
      "rtc_ds1307"
      "rtc_pcf8563"
    ];

    # Add boot options for PiKVM
    boot.kernelParams = [
      "hdmi_force_hotplug=1"
      "gpu_mem=128"
      "enable_uart=1"
      "dtoverlay=tc358743"
      "dtoverlay=disable-bt"
      "dtoverlay=dwc2,dr_mode=peripheral"
    ];

    # Specify initramfs
    # boot.initrd.kernel = "initramfs-linux.img";
  };
}
