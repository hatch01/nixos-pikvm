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

## ✅ What's Working

- 🌐 **Remote Access:**
  Access your PiKVM web UI from anywhere, with real-time MJPEG video streaming and full keyboard/mouse control.

- 💾 **ISO Upload:**
  Easily upload ISO images to your Raspberry Pi for virtual media mounting.

---

## 📝 TODO & Roadmap

- 🧹 **Module Cleanup:**
  Refactor and polish the NixOS module for maintainability and clarity.

- 🔄 **Exact nginx Config Parity:**
  Ensure the nginx configuration matches the official PiKVM `kvmd` setup exactly for full compatibility.

- 📚 **Installation Documentation:**
  Write step-by-step instructions for installing on NixOS, including disk formatting (potentially using [disko](https://github.com/nix-community/disko) for automated setup).

- 🚀 **Virtual Media Mounting Support:**
  Add support for mounting virtual media (such as ISO images) directly through PiKVM.

- ⬆️ **Upstream to nixpkgs:**
  Prepare and submit the module/package for inclusion in the official [nixpkgs](https://github.com/NixOS/nixpkgs) repository.

---

## 🛠️ Configuration Options

| Option                        | Type      | Default      | Description                                         |
|-------------------------------|-----------|--------------|-----------------------------------------------------|
| `enable`                      | `bool`    | `false`      | 🟢 Enable the PiKVM daemon                          |
| `package`                     | `package` | `pkgs.kvmd`  | 📦 kvmd package to use                              |
| `withTesseract`               | `bool`    | `false`      | 👁️ Enable OCR with Tesseract                        |
| `nginx.enable`                | `bool`    | `true`       | 🌐 Enable nginx web server for PiKVM                |
| `nginx.httpPort`              | `port`    | `80`         | 🌐 HTTP port for nginx                              |
| `nginx.httpsPort`             | `port`    | `443`        | 🔒 HTTPS port for nginx                             |
| `nginx.httpsEnabled`          | `bool`    | `true`       | 🔒 Enable HTTPS support                             |

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

- TODO later

## 🤝 Contributing

I love contributions! 💝
Dont hesitate to open issues or pull requests for bugs, features, or improvements.

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
