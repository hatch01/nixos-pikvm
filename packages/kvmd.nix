{
  lib,
  fetchFromGitHub,
  python312,
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
  sudo,
  withTesseract ? false,
  pkg-config,
  openssl,
  makeWrapper,
  bash,
  libgpiod,
}:
python312.pkgs.buildPythonApplication rec {
  pname = "kvmd";
  version = "4.47";

  src = fetchFromGitHub {
    owner = "pikvm";
    repo = "kvmd";
    rev = "v${version}";
    sha256 = "sha256-Z62MDtGLNPA08nMayALerCwxm6YaPRM6/Wcw4oQ0wdE=";
  };

  # src = builtins.path {
  #   path = "/home/eymeric/tmp/kvmd";
  #   name = "kvmd-src";
  # };

  propagatedBuildInputs = with python312.pkgs;
    [
      aiofiles
      aiohttp
      async-lru
      bcrypt
      dbus-next
      dbus-python
      evdev
      hidapi
      ldap
      netifaces
      pam
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
      (import ../packages/luma.nix {
        pkgs = pkgs;
        python3 = python312;
      })
      (import ../packages/python-gpiod.nix {
        pkgs = pkgs;
        python3 = python312;
      })
      libgpiod
      (import ./python-systemd.nix {
        inherit lib fetchFromGitHub pkg-config systemd;
        buildPythonPackage = python312.pkgs.buildPythonPackage;
        setuptools = python312.pkgs.setuptools;
      })
      xlib
      zstandard
      binutils
      python-periphery
    ]
    ++ [
      ustreamer
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
      sudo
      openssl
      libgpiod
    ];

  nativeBuildInputs = [makeWrapper bash] ++ lib.optional withTesseract tesseract;

  patchPhase = ''
    substituteInPlace setup.py \
      --replace "#!/usr/bin/env python3" "#!${python312}/bin/python3"
    substituteInPlace genmap.py \
      --replace "#!/usr/bin/env python3" "#!${python312}/bin/python3"
    substituteInPlace kvmd/apps/__init__.py \
      --replace "/usr/bin/vcgencmd" "${libraspberrypi}/bin/vcgencmd" \
      --replace "/usr/bin/sudo" "${sudo}/bin/sudo" \
      --replace "/usr/bin/kvmd-helper-pst-remount" "$out/bin/kvmd-helper-pst-remount" \
      --replace "/usr/bin/ip" "${iproute2}/bin/ip" \
      --replace "/usr/bin/systemd-run" "${systemd}/bin/systemd-run" \
      --replace "/usr/bin/systemctl" "${systemd}/bin/systemctl" \
      --replace "/usr/bin/janus" "${janus-gateway}/bin/janus"
    substituteInPlace kvmd/apps/edidconf/__init__.py \
      --replace "/usr/bin/v4l2-ctl" "${v4l-utils}/bin/v4l2-ctl"
    substituteInPlace kvmd/plugins/ugpio/ipmi.py \
      --replace "/usr/bin/ipmitool" "${ipmitool}/bin/ipmitool"
    substituteInPlace kvmd/plugins/msd/otg/__init__.py \
      --replace "/usr/bin/sudo" "${sudo}/bin/sudo" \
      --replace "/usr/bin/kvmd-helper-otgmsd-remount" "$out/bin/kvmd-helper-otgmsd-remount"
    substituteInPlace hid/arduino/avrdude.py \
      --replace "/usr/bin/avrdude" "${avrdude}/bin/avrdude"
    substituteInPlace kvmd/apps/oled/sensors.py \
      --replace "#!/usr/bin/env python3" "#!${python312}/bin/python3"
    substituteInPlace kvmd/apps/oled/screen.py \
      --replace "#!/usr/bin/env python3" "#!${python312}/bin/python3"
    substituteInPlace kvmd/apps/oled/__init__.py \
      --replace "#!/usr/bin/env python3" "#!${python312}/bin/python3"
  '';

  postInstall = ''
    wrapProgram $out/bin/kvmd \
      --suffix PYTHONPATH : $out/lib/python3.12/site-packages \
      --suffix LD_LIBRARY_PATH : ${lib.makeLibraryPath ([stdenv.cc.libc libxkbcommon] ++ lib.optional withTesseract tesseract)}
    # Install all contrib keymaps
    mkdir -p $out/share/kvmd/keymaps
    cp -r $src/contrib/keymaps/* $out/share/kvmd/keymaps/
    # Install kvmd-gencert script and make it executable

    install -Dm755 $src/scripts/kvmd-gencert $out/bin/kvmd-gencert
    substituteInPlace $out/bin/kvmd-gencert \
      --replace '/bin/bash' ${bash}/bin/bash
    wrapProgram $out/bin/kvmd-gencert \
      --prefix PATH : ${lib.makeBinPath [openssl coreutils]}
  '';

  meta = with lib; {
    description = "KVM over IP for Raspberry Pi and other devices";
    homepage = "https://github.com/pikvm/kvmd";
    license = licenses.gpl3Plus;
    maintainers = with maintainers; [eymeric];
    platforms = platforms.linux;
    mainProgram = "kvmd";
    longDescription = ''
      PiKVM daemon - the main daemon that drives a Pi-based KVM over IP device.
      OCR support is ${
        if withTesseract
        then "enabled"
        else "disabled"
      }.
    '';
  };
}
