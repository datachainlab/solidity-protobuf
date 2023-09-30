{
  description = "Protobuf Solidity compiler";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
      ];
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin" ];
      perSystem = { config, self', inputs', pkgs, system, ... }: {
        packages.default = pkgs.python3Packages.buildPythonPackage rec {
          pname = "protobuf-solidity";
          version = "0.1";
          src = ./.;
          doCheck = false;
          PROTOC = "${pkgs.protobuf}/bin/protoc";
          runtimeInputs = [ pkgs.python3 ];
          runtimeDeps = [ pkgs.python3 ];
          propagatedBuildInputs = [
            pkgs.python3Packages.protobuf
            pkgs.python3Packages.wrapt
          ];
        };

        devShells.default = pkgs.mkShell {
          packages =
            [
              pkgs.python3
              pkgs.protobuf
              pkgs.python3Packages.protobuf3
              pkgs.python3Packages.wrapt
              pkgs.python3Packages.google
            ];
        };

      };
      flake = { };
    };
}
