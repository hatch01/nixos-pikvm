{
  lib,
  fetchFromGitHub,
  python3,
  tesseract,
  avrdude,
  stdenv,
  binutils,
  ustreamer,
  janus-gateway,
  v4l-utils,
  coreutils,
  iproute2,
  ipmitool,
  dnsmasq,
  systemd,
  libxkbcommon,
  glibc,
  libraspberrypi,
  util-linux,
  iptables,
  withTesseract ? false,
  openssl,
  makeWrapper,
  bash,
  libgpiod,
  mount,
  sudo,
}:
python3.pkgs.buildPythonApplication rec {
  pname = "kvmd";
  version = "4.125";

  src = fetchFromGitHub {
    owner = "pikvm";
    repo = "kvmd";
    rev = "v${version}";
    sha256 = "sha256-IKtiSe3zZOdQ8ktLVD9ewGZyAnFM+FYHfSZM1fP6fzA=";
  };
  pyproject = true;
  build-system = with python3.pkgs; [ setuptools ];

  passthru = {
    helpers = {
      otgmsdRemount = "${placeholder "out"}/bin/kvmd-helper-otgmsd-remount";
      pstRemount = "${placeholder "out"}/bin/kvmd-helper-pst-remount";
    };
  };

  # src = builtins.path {
  #   path = "/home/eymeric/tmp/kvmd";
  #   name = "kvmd-src";
  # };

  propagatedBuildInputs =
    with python3.pkgs;
    [
      aiofiles
      aiohttp
      async-lru
      bcrypt
      dbus-next
      dbus-python
      evdev
      hidapi
      python-ldap
      mako
      netifaces
      python-pam
      passlib
      pillow
      psutil
      pyaml
      pyghmi
      pygments
      pyotp
      pyrad
      pyserial
      pyserial-asyncio
      python-periphery
      pyusb
      pyudev
      qrcode
      setproctitle
      six
      spidev
      luma-core
      python3.pkgs.libgpiod
      python3.pkgs.systemd-python
      xlib
      zstandard
      binutils
      python-periphery
      ruamel-base
      ruamel-yaml
    ]
    ++ [
      (ustreamer.override { withPython = true; })
      janus-gateway
      v4l-utils
      coreutils
      iproute2
      ipmitool
      dnsmasq
      systemd
      tesseract
      libxkbcommon
      glibc
      libraspberrypi
      util-linux
      iptables
      openssl
      libgpiod
    ];

  nativeBuildInputs = [
    makeWrapper
    bash
  ]
  ++ lib.optional withTesseract tesseract;

  patchPhase = ''
    substituteInPlace setup.py \
      --replace-fail "#!/usr/bin/env python3" "#!${python3}/bin/python3"
    substituteInPlace genmap.py \
      --replace-fail "#!/usr/bin/env python3" "#!${python3}/bin/python3"
    substituteInPlace kvmd/apps/_scheme.py \
      --replace-fail "/usr/bin/vcgencmd" "${libraspberrypi}/bin/vcgencmd" \
      --replace-fail "/usr/bin/sudo" "${sudo}" \
      --replace-fail "/usr/bin/kvmd-helper-pst-remount" "${placeholder "out"}/bin/kvmd-helper-pst-remount" \
      --replace-fail "/usr/bin/ip" "${iproute2}/bin/ip" \
      --replace-fail "/usr/bin/systemd-run" "${systemd}/bin/systemd-run" \
      --replace-fail "/usr/bin/systemctl" "${systemd}/bin/systemctl" \
      --replace-fail "/usr/bin/janus" "${janus-gateway}/bin/janus" \
      --replace-fail "/bin/true" "${coreutils}/bin/true" \
      --replace-fail "/usr/sbin/iptables" "${iptables}/bin/iptables"
    substituteInPlace kvmd/helpers/remount/__init__.py \
      --replace-fail "/bin/mount" "${mount}/bin/mount"
    substituteInPlace kvmd/apps/edidconf/__init__.py \
      --replace-fail "/usr/bin/v4l2-ctl" "${v4l-utils}/bin/v4l2-ctl"
    substituteInPlace kvmd/plugins/ugpio/ipmi.py \
      --replace-fail "/usr/bin/ipmitool" "${ipmitool}/bin/ipmitool"
    substituteInPlace kvmd/plugins/msd/otg/__init__.py \
      --replace-fail "/usr/bin/sudo" "${sudo}" \
      --replace-fail "/usr/bin/kvmd-helper-otgmsd-remount" "${placeholder "out"}/bin/kvmd-helper-otgmsd-remount"
    substituteInPlace hid/arduino/avrdude.py \
      --replace-fail "/usr/bin/avrdude" "${avrdude}/bin/avrdude"

    substituteInPlace kvmd/apps/otg/__init__.py \
      --replace-fail "os.mkdir(path)" "os.makedirs(path, exist_ok=True)"

    # Fix hardcoded default paths in argparse that fail validation in NixOS
    # Remove type validators from argument defaults since argparse validates defaults
    # even when not used. In NixOS we always provide paths explicitly via systemd.
    substituteInPlace kvmd/apps/__init__.py \
      --replace-fail 'parser.add_argument("--main-config", default="/usr/lib/kvmd/main.yaml", type=valid_abs_file,' \
                     'parser.add_argument("--main-config", default="/usr/lib/kvmd/main.yaml",' \
      --replace-fail 'parser.add_argument("--legacy-auth-config", default="/etc/kvmd/auth.yaml", type=valid_abs_path,' \
                     'parser.add_argument("--legacy-auth-config", default="/etc/kvmd/auth.yaml",' \
      --replace-fail 'parser.add_argument("--override-dir", default="/etc/kvmd/override.d", type=valid_abs_dir,' \
                     'parser.add_argument("--override-dir", default="/etc/kvmd/override.d",' \
      --replace-fail 'parser.add_argument("--override-config", default="/etc/kvmd/override.yaml", type=valid_abs_file,' \
                     'parser.add_argument("--override-config", default="/etc/kvmd/override.yaml",'

    # Patch config files
    for file in configs/kvmd/main/*.yaml; do
      substituteInPlace "$file" \
        --replace-fail "/usr/bin/ustreamer" "${lib.getExe ustreamer}" \
        --replace-fail "/usr/share/kvmd/configs.default/kvmd" "$out/etc/kvmd/kvmd/main/"
    done
    cat configs/kvmd/main/v2-hdmi-rpi4.yaml

  '';

  postInstall = ''
    wrapProgram $out/bin/kvmd \
      --suffix PYTHONPATH : $out/lib/python3.12/site-packages \
      --suffix LD_LIBRARY_PATH : ${
        lib.makeLibraryPath (
          [
            stdenv.cc.libc
            libxkbcommon
          ]
          ++ lib.optional withTesseract tesseract
        )
      }
    # Install all contrib keymaps
    mkdir -p $out/share/kvmd/keymaps
    cp -r contrib/keymaps/* $out/share/kvmd/keymaps/

    # Install web files
    mkdir -p $out/share/kvmd/web
    if [ -d "web" ]; then
      cp -r web/* $out/share/kvmd/web/
    fi

    # Install kvmd-gencert script and make it executable
    install -Dm755 scripts/kvmd-gencert $out/bin/kvmd-gencert
    substituteInPlace $out/bin/kvmd-gencert \
      --replace-fail '/bin/bash' ${bash}/bin/bash
    wrapProgram $out/bin/kvmd-gencert \
      --prefix PATH : ${
        lib.makeBinPath [
          openssl
          coreutils
        ]
      }

    # Install config files
    mkdir -p $out/etc/kvmd
    cp -r configs/* $out/etc/
  '';

  meta = with lib; {
    description = "KVM over IP for Raspberry Pi and other devices";
    homepage = "https://github.com/pikvm/kvmd";
    license = licenses.gpl3Plus;
    maintainers = with maintainers; [ eymeric ];
    platforms = platforms.linux;
    mainProgram = "kvmd";
    longDescription = ''
      PiKVM daemon - the main daemon that drives a Pi-based KVM over IP device.
      OCR support is ${if withTesseract then "enabled" else "disabled"}.
    '';
  };
}
