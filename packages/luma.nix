{
  pkgs,
  python3,
}:
python3.pkgs.buildPythonPackage rec {
  pname = "luma.core";
  version = "2.4.0";

  src = pkgs.fetchPypi {
    inherit pname version;
    sha256 = "sha256-z1/fNWPV7Fbi95LzovQyq66sUXoLBaEKdXpMWia7Ll0=";
  };

  propagatedBuildInputs = with python3.pkgs; [setuptools pillow];
}
