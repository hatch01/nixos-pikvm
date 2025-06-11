# 🖥️ NixOS PiKVM 🥧

[![NixOS](https://img.shields.io/badge/NixOS-5277C3?style=for-the-badge&logo=nixos&logoColor=white)](https://nixos.org/)
[![PiKVM](https://img.shields.io/badge/PiKVM-FF6B35?style=for-the-badge&logo=raspberry-pi&logoColor=white)](https://pikvm.org/)
[![Flakes](https://img.shields.io/badge/Nix_Flakes-7E7EFF?style=for-the-badge&logo=nixos&logoColor=white)](https://nixos.wiki/wiki/Flakes)

> 🚀 **Transform your NixOS system into a powerful KVM-over-IP solution!** 🌟

## 🎯 What is this?

This project brings the awesome **PiKVM** experience to **NixOS** through a clean, declarative configuration! 🎉

**PiKVM** turns your device into a remote KVM (Keyboard, Video, Mouse) solution, allowing you to:
- 🖱️ Control computers remotely
- 📺 View their screens in real-time
- ⌨️ Type on their keyboards
- 🔌 Manage power states
- 💾 Mount virtual drives
- 🔒 Access BIOS/UEFI settings

All through a beautiful web interface! ✨

## ✨ Features

- 🏗️ **Declarative Configuration** - Pure NixOS module approach
- 📦 **Flake-based** - Modern Nix development experience
- 🔧 **Configurable** - Customize hostname, OCR support, and more
- 🛡️ **Secure** - Proper user/group isolation
- 🎮 **Multi-architecture** - Supports x86_64 and ARM64
- 🖼️ **OCR Support** - Optional Tesseract integration for text recognition
- 🌊 **µStreamer Integration** - High-performance video streaming

## 🚀 Quick Start

### 1️⃣ Add to your flake

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    pikvm.url = "github:yourusername/nixos-pikvm";
  };

  outputs = { self, nixpkgs, pikvm }: {
    nixosConfigurations.your-system = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        pikvm.nixosModules.default
        {
          services.kvmd.enable = true;
        }
      ];
    };
  };
}
```

### 2️⃣ Basic Configuration

```nix
{
  services.kvmd = {
    enable = true;
    withTesseract = true;           # 👁️ Enable OCR support
  };
}
```

### 3️⃣ Rebuild and Enjoy!

```bash
sudo nixos-rebuild switch
```

That's it! 🎊 Your PiKVM is ready to rock!

## 🛠️ Configuration Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enable` | `bool` | `false` | 🟢 Enable the PiKVM daemon |
| `package` | `package` | `pkgs.kvmd` | 📦 kvmd package to use |
| `withTesseract` | `bool` | `false` | 👁️ Enable OCR with Tesseract |

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   🌐 Web UI     │    │  🎥 µStreamer   │    │  🖥️ Target PC   │
│   (Your Browser)│◄──►│   (Video Feed)  │◄──►│   (Controlled)  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         ▲                       ▲
         │                       │
         ▼                       ▼
┌─────────────────────────────────────────────────────────────────┐
│                    🧠 KVMD Daemon                              │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌───────────┐ │
│  │ 🎮 HID      │ │ 📺 Video    │ │ 🔌 GPIO     │ │ 💾 MSD    │ │
│  │ Control     │ │ Capture     │ │ Control     │ │ Emulation │ │
│  └─────────────┘ └─────────────┘ └─────────────┘ └───────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

## 🎛️ Advanced Configuration

### Custom Package Override

```nix
{
  services.kvmd = {
    enable = true;
    package = pkgs.kvmd.override {
      withTesseract = true;
      # Add more overrides here
    };
  };
}
```

### Integration with Other Services

```nix
{
  services.kvmd.enable = true;

  # 🔥 Firewall configuration
  networking.firewall.allowedTCPPorts = [ 80 443 8080 8081 ];

  # 🛡️ HTTPS with Let's Encrypt
  services.nginx = {
    enable = true;
    # Your nginx config here
  };
}
```

## 🐛 Troubleshooting

### 🔍 Check Service Status
```bash
sudo systemctl status kvmd
sudo systemctl status ustreamer
```

### 📋 View Logs
```bash
sudo journalctl -u kvmd -f
sudo journalctl -u ustreamer -f
```

### 🏥 Common Issues

- **🚫 Permission denied**: Ensure your user is in the `kvmd` group
- **📺 No video**: Check ustreamer service and video device permissions
- **🌐 Can't access web UI**: Verify firewall settings and port availability

## 🤝 Contributing

We love contributions! 💝

1. 🍴 Fork the repository
2. 🌿 Create a feature branch
3. 💻 Make your changes
4. ✅ Test thoroughly
5. 🚀 Submit a pull request

## 📚 Related Projects

- 🥧 [PiKVM](https://github.com/pikvm/kvmd) - The original PiKVM project
- 📺 [µStreamer](https://github.com/pikvm/ustreamer) - Lightweight streaming server
- ❄️ [nixpkgs](https://github.com/NixOS/nixpkgs) - The Nix packages collection

## 📄 License

This project is licensed under the GPL-3.0+ License - see the original [PiKVM license](https://github.com/pikvm/kvmd/blob/master/LICENSE) for details.

## 🌟 Star History

If this project helped you, please consider giving it a ⭐! It helps others discover this awesome NixOS integration.

---

<div align="center">

**Made with ❤️ for the NixOS and PiKVM communities**

🐧 **NixOS** × 🥧 **PiKVM** = 🚀 **Awesome Remote Management**

</div>
