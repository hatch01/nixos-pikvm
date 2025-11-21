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
      ldap
      mako
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
      luma-core
      python3.pkgs.libgpiod
      python3.pkgs.systemd
      xlib
      zstandard
      binutils
      python-periphery
    ]
    ++ [
      (ustreamer.override {withPython = true;})
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
      --replace "#!/usr/bin/env python3" "#!${python3}/bin/python3"
    substituteInPlace genmap.py \
      --replace "#!/usr/bin/env python3" "#!${python3}/bin/python3"
    substituteInPlace kvmd/apps/__init__.py \
      --replace "/usr/bin/vcgencmd" "${libraspberrypi}/bin/vcgencmd" \
      --replace "/usr/bin/sudo" "/run/wrappers/bin/sudo" \
      --replace "/usr/bin/kvmd-helper-pst-remount" "$out/bin/kvmd-helper-pst-remount" \
      --replace "/usr/bin/ip" "${iproute2}/bin/ip" \
      --replace "/usr/bin/systemd-run" "${systemd}/bin/systemd-run" \
      --replace "/usr/bin/systemctl" "${systemd}/bin/systemctl" \
      --replace "/usr/bin/janus" "${janus-gateway}/bin/janus" \
      --replace "/bin/true" "${coreutils}/bin/true" \
      --replace "/bin/false" "${coreutils}/bin/false" \
      --replace "/usr/sbin/iptables" "${iptables}/bin/iptables"
    substituteInPlace kvmd/helpers/remount/__init__.py \
      --replace "/bin/mount" "${mount}/bin/mount"
    substituteInPlace kvmd/apps/edidconf/__init__.py \
      --replace "/usr/bin/v4l2-ctl" "${v4l-utils}/bin/v4l2-ctl"
    substituteInPlace kvmd/plugins/ugpio/ipmi.py \
      --replace "/usr/bin/ipmitool" "${ipmitool}/bin/ipmitool"
    substituteInPlace kvmd/plugins/msd/otg/__init__.py \
      --replace "/usr/bin/sudo" "/run/wrappers/bin/sudo" \
      --replace "/usr/bin/kvmd-helper-otgmsd-remount" "$out/bin/kvmd-helper-otgmsd-remount"
    substituteInPlace hid/arduino/avrdude.py \
      --replace "/usr/bin/avrdude" "${avrdude}/bin/avrdude"
    substituteInPlace kvmd/apps/oled/sensors.py \
      --replace "#!/usr/bin/env python3" "#!${python3}/bin/python3"
    substituteInPlace kvmd/apps/oled/screen.py \
      --replace "#!/usr/bin/env python3" "#!${python3}/bin/python3"
    substituteInPlace kvmd/apps/oled/__init__.py \
      --replace "#!/usr/bin/env python3" "#!${python3}/bin/python3"

    substituteInPlace kvmd/apps/otg/__init__.py \
      --replace "os.mkdir(path)" "os.makedirs(path, exist_ok=True)"

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
    cp -r $src/contrib/keymaps/* $out/share/kvmd/keymaps/

    # Install web files
    mkdir -p $out/share/kvmd/web
    if [ -d "$src/web" ]; then
      cp -r $src/web/* $out/share/kvmd/web/
    fi

    # Install kvmd-gencert script and make it executable
    install -Dm755 $src/scripts/kvmd-gencert $out/bin/kvmd-gencert
    substituteInPlace $out/bin/kvmd-gencert \
      --replace '/bin/bash' ${bash}/bin/bash
    wrapProgram $out/bin/kvmd-gencert \
      --prefix PATH : ${
        lib.makeBinPath [
          openssl
          coreutils
        ]
      }
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
