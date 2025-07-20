{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
    crane.url = "https://flakehub.com/f/ipetkov/crane/0.20.tar.gz";
  };

  outputs = { nixpkgs, rust-overlay, flake-utils, crane, ... }: 
    flake-utils.lib.eachDefaultSystem (system: let
      version = "v0.100.5";
      
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ (import rust-overlay) ];
      };

      src = pkgs.fetchFromGitHub {
        owner = "antinomyhq";
        repo = "forge";
        tag = version;
        hash = "sha256-l+AD3krCtTCK89I01n/WRdQZEw+CL0F+UmmCH0GTdrg=";
      };
      
      toolchain = p: p.rust-bin.stable.latest.default.override {
        extensions = [ "rustfmt" "clippy" ];
      };

      craneLib = (crane.mkLib pkgs).overrideToolchain toolchain;
      commonArgs = {
        pname = "forge";
        inherit version;

        doCheck = false;
        cargoCheckCommand = "#";
        cargoExtraArgs = "--locked -p forge_main";
        dummySrc = src;
        strictDeps = true;
      };
      forge = craneLib.buildPackage (commonArgs // {
        inherit src;
        cargoArtifacts = craneLib.buildDepsOnly commonArgs;
        cargoExtraArgs = "--locked -p forge_main";
      });
    in {
      packages = {
        inherit forge;
        default = forge;
      };
    });
}
