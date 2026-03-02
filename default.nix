{ pkgconf, libinput, libcap, ocamlPackages }:
# (don't know why libcap isn't pulled in automatically by Nix's libinput package)

ocamlPackages.buildDunePackage {
  pname = "libinput";
  version = "0.1";

  src = ./.;

  nativeBuildInputs = [ pkgconf ];
  buildInputs = [ ocamlPackages.dune-configurator ];
  propagatedBuildInputs = [ libinput libcap ] ++ (with ocamlPackages; [ ctypes-foreign ctypes fmt ]);
}
