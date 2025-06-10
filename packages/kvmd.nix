{ lib
, fetchFromGitHub
, python3
, tesseract
, stdenv
, binutils
, withTesseract ? false
}:

python3.pkgs.buildPythonApplication rec {
  pname = "kvmd";
  version = "4.82";

  src = fetchFromGitHub {
    owner = "pikvm";
    repo = "kvmd";
    rev = "v${version}";
    sha256 = "sha256-6ooWvycNRRADV/OuJNyionfuV1RRPQokgf1EPpYdEEM=";
  };

  propagatedBuildInputs = with python3.pkgs; [
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
    systemd
    xlib
    zstandard
    binutils
  ];

  nativeBuildInputs = lib.optional withTesseract tesseract;

  postInstall = ''
    wrapProgram $out/bin/kvmd \
      --suffix LD_LIBRARY_PATH : ${lib.makeLibraryPath ([ stdenv.cc.libc ] ++ lib.optional withTesseract tesseract)}
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
