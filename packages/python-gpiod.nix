{
  pkgs,
  python3,
}:
python3.pkgs.buildPythonPackage rec {
  pname = "gpiod";
  version = "2.3.0";

  src = pkgs.fetchPypi {
    inherit pname version;
    sha256 = "sha256-2qhA7VtpHnB4qc8hx5/oE7mpHD7Qvbr64Bgce5i4AwA=";
  };

  build-system = with python3.pkgs; [ setuptools ];
  pyproject = true;
  propagatedBuildInputs = with python3.pkgs; [ setuptools ];

  meta = with pkgs.lib; {
    description = "Python bindings for libgpiod";
    homepage = "https://github.com/brgl/libgpiod";
    license = licenses.lgpl21Plus;
  };
}
