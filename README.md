# 🖥️ NixOS PiKVM 🥧

[![NixOS](https://img.shields.io/badge/NixOS-5277C3?style=for-the-badge&logo=nixos&logoColor=white)](https://nixos.org/)
[![PiKVM](https://img.shields.io/badge/PiKVM-FF6B35?style=for-the-badge&logo=raspberry-pi&logoColor=white)](https://pikvm.org/)

> 🚀 **Transform your NixOS system into a powerful KVM-over-IP solution!** 🌟

## What is this?

This project brings the awesome **PiKVM** experience to **NixOS** through a clean, declarative configuration! 🎉

## Whats Working

- Video streaming
  - Direct H264 (need https enabled)
  - Legacy MJPEG
- Remote control (mouse + keyboard)
- Virtual drive
- Gpio control (Used for ATX control)
- Nix declarative configuration

## Whats not Working

- VIdeo streaming webRTC h264


## How to Install (Raspberry Pi Example)

This section outlines a typical installation workflow for NixOS PiKVM on a Raspberry Pi, inspired by a real-world home lab setup.

### Prepare Your Configuration

Create a NixOS configuration for your Raspberry Pi.

```nix
{
  imports = [
    inputs.pikvm.nixosModules.default
  ];

  services.kvmd = {
    enable = true;
    package = inputs.pikvm.packages.aarch64-linux.default;
    hardwareVersion = "v2-hdmi-rpi4";
  };

  # ...other options (see linked config for details)
}
```

### Generate the SD Card Image

Use [`nixos-generators`](https://github.com/nix-community/nixos-generators) to build an SD image:

```bash
nix run nixpkgs#nixos-generators -- -f sd-aarch64 --flake .#<machine> --system aarch64-linux -o ./<machine>-sd-aarch64
```

Replace `<machine>` with your hostname or flake target.

### Flash the Image

Flash the generated image to your SD card using a tool like [Caligula](https://github.com/ifd3f/caligula) or `dd`.

### Partitioning

After flashing, add two ext4 partitions to your SD card:
- **PIMSD**: Used for virtual USB (make it large enough for your ISOs)
- **PIPST**: Used for PiKVM persistent storage

You can use `gparted` or `fdisk` for partitioning.

### Boot & Test

Insert the SD card, boot your Raspberry Pi, and cross your fingers!

### available options : 


In services.kvmd :

| Option                          | Type      | Description                                         | Example Value            |
|----------------------------------|-----------|-----------------------------------------------------|-------------------------|
| enable                          | boolean   | Enable the kvmd service                             | true                    |
| package                         | package   | The kvmd package to use                             | inputs.pikvm.packages.aarch64-linux.default |
| hardwareVersion                  | string    | PiKVM hardware version                              | "v2-hdmi-rpi4"          |
| configFile                       | path      | Path to custom kvmd config file                     | "/etc/kvmd/kvmd.yaml"   |
| extraConfig                      | attrs     | Extra kvmd configuration options                    | { ... }                 |
| user                             | string    | Username for PiKVM web UI                           | "admin"                 |
| passwordFile                     | path      | Path to password file for web UI                    | "/etc/kvmd/password"    |
| openFirewall                     | boolean   | Open firewall ports for kvmd                        | true                    |
| gpio.enable                      | boolean   | Enable GPIO controls                                | true                    |
| virtualDrive.enable              | boolean   | Enable virtual USB drive                            | true                    |
| video.enable                     | boolean   | Enable video streaming                              | true                    |
| web.enable                       | boolean   | Enable PiKVM web interface                          | true                    |
| extraArgs                        | list      | Extra command-line arguments for kvmd               | [ "--debug" ]           |
| nginx.enable                     | boolean   | Enable nginx web server for PiKVM                   | true                    |
| nginx.httpPort                   | port      | HTTP port for nginx                                 | 80                      |
| nginx.httpsPort                  | port      | HTTPS port for nginx                                | 443                     |
| nginx.httpsEnabled               | boolean   | Enable HTTPS support                                | true                    |

## Contributing

I love contributions! 💝
Dont hesitate to open issues or pull requests for bugs, features, or improvements.

##  Related Projects

- 🥧 [PiKVM](https://github.com/pikvm/kvmd) - The original PiKVM project
- ❄️ [nixpkgs](https://github.com/NixOS/nixpkgs) - The Nix packages collection
- 🖥️ [nixos-hardware](https://github.com/NixOS/nixos-hardware) - Community-maintained hardware configuration collection for NixOS

## License

This project is licensed under the GPL-3.0+ License - see the original [PiKVM license](https://github.com/pikvm/kvmd/blob/master/LICENSE) for details.

---

<div align="center">

**Made with ❤️ for the NixOS and PiKVM communities**

</div>
