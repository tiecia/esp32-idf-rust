{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = {
    self,
    nixpkgs,
  }: let
    system = "x86_64-linux";
    pkgs = import nixpkgs { 
      inherit system; 
      config = {
        permittedInsecurePackages = [ "python-2.7.18.8" ];
      };
    };
    esp32 = pkgs.dockerTools.pullImage {
      imageName = "espressif/idf-rust";
      imageDigest = "sha256:83a40f1feeeb9eb3e5c00055b313d8cbe2201de1ee8455f2ffc00f7e71dddf0d";
      sha256 = "0kikm5v91y0s86kx7wkrb2cm52dd0pq4ll58bv0xdbmnfxl374al";
      finalImageName = "espressif/idf-rust";
      finalImageTag = "esp32_latest";
    };
  in {
    packages.${system}.esp32 = pkgs.stdenv.mkDerivation {
      name = "esp32";
      src = esp32;
      unpackPhase = ''
        mkdir -p source
        tar -C source -xvf $src
      '';
      sourceRoot = "source";
      nativeBuildInputs = [
        pkgs.autoPatchelfHook
        pkgs.jq
      ];
      buildInputs = [
        pkgs.xz
        pkgs.zlib
        pkgs.libxml2
        pkgs.python2
        pkgs.libudev-zero
        pkgs.stdenv.cc.cc
      ];
      buildPhase = ''
        jq -r '.[0].Layers | @tsv' < manifest.json > layers
      '';
      installPhase = ''
        mkdir -p $out
        for i in $(< layers); do
          tar -C $out -xvf "$i" home/esp/.cargo home/esp/.rustup || true
        done
        mv -t $out $out/home/esp/{.cargo,.rustup}
        rmdir $out/home/esp
        rmdir $out/home
        # [ -d $out/.cargo ] && [ -d $out/.rustup ]
      '';
    };
  };
}
