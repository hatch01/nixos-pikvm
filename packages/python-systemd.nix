{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  setuptools,
  pkg-config,
  systemd,
}:
buildPythonPackage rec {
  pname = "python-systemd";
  version = "235";

  src = fetchFromGitHub {
    owner = "systemd";
    repo = "python-systemd";
    rev = "v${version}";
    sha256 = "sha256-8p4m4iM/z4o6PHRQIpuSXb64tPTWGlujEYCDVLiIt2o=";
  };

  pyproject = true;
  build-system = [
    setuptools
    pkg-config
  ];
  buildInputs = [
    setuptools
    systemd
  ];
  nativeBuildInputs = [ pkg-config ];

  meta = with lib; {
    description = "Python bindings for systemd";
    homepage = "https://github.com/systemd/python-systemd";
    license = licenses.lgpl21Plus;
  };
}
