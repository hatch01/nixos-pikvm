{
  lib,
  stdenv,
  fetchFromGitHub,
  libbsd,
  libevent,
  libjpeg,
  libdrm,
  pkg-config,
  janus-gateway,
  glib,
  alsa-lib,
  speex,
  jansson,
  libopus,
  nixosTests,
  systemdLibs,
  which,
  python312,
  python312Packages,
  withSystemd ? true,
  withJanus ? true,
  withPython ? true,
}:
stdenv.mkDerivation rec {
  pname = "ustreamer";
  version = "6.31";

  src = fetchFromGitHub {
    owner = "pikvm";
    repo = "ustreamer";
    rev = "v${version}";
    hash = "sha256-SvvIY52FMO6Y4B6TOfk7dLtci4OayPX6+d8voKenKbQ=";
  };

  buildInputs =
    [
      libbsd
      libevent
      libjpeg
      libdrm
    ]
    ++ lib.optionals withSystemd [
      systemdLibs
    ]
    ++ lib.optionals withJanus [
      janus-gateway
      glib
      alsa-lib
      jansson
      speex
      libopus
    ]
    ++ lib.optionals withPython [
      python312
      python312Packages.setuptools
      python312Packages.wheel
      python312Packages.build
      python312Packages.pip
    ];

  nativeBuildInputs =
    [
      pkg-config
      which
    ]
    ++ lib.optionals withPython [
      python312Packages.setuptools
      python312Packages.wheel
      python312Packages.build
      python312Packages.pip
    ];

  makeFlags =
    [
      "PREFIX=${placeholder "out"}"
      "WITH_V4P=1"
    ]
    ++ lib.optionals withSystemd [
      "WITH_SYSTEMD=1"
    ]
    ++ lib.optionals withJanus [
      "WITH_JANUS=1"
      "CFLAGS=-I${lib.getDev janus-gateway}/include/janus"
    ]
    ++ lib.optionals withPython [
      "WITH_PYTHON=1"
    ];

  enableParallelBuilding = true;

  passthru.tests = { inherit (nixosTests) ustreamer; };

  meta = with lib; {
    homepage = "https://github.com/pikvm/ustreamer";
    description = "Lightweight and fast MJPG-HTTP streamer";
    longDescription = ''
      µStreamer is a lightweight and very quick server to stream MJPG video from
      any V4L2 device to the net. All new browsers have native support of this
      video format, as well as most video players such as mplayer, VLC etc.
      µStreamer is a part of the Pi-KVM project designed to stream VGA and HDMI
      screencast hardware data with the highest resolution and FPS possible.
    '';
    license = licenses.gpl3Plus;
    maintainers = with maintainers; [
      tfc
      matthewcroughan
    ];
    platforms = platforms.linux;
    mainProgram = "ustreamer";
  };
}
