{
  description = "Minimalist HUST network authentication tool";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        packages.default = pkgs.rustPlatform.buildRustPackage {
          pname = "hust-network-login";
          version = "0.1.3";

          src = ./.;

          cargoLock = {
            lockFile = ./Cargo.lock;
          };

          meta = with pkgs.lib; {
            description = "Minimalist HUST network authentication tool";
            homepage = "https://github.com/black-binary/hust-network-login";
            license = licenses.unlicense;
            maintainers = [ ];
            mainProgram = "hust-network-login";
          };
        };

        apps.default = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/hust-network-login";
        };

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            rustc
            cargo
            rust-analyzer
            clippy
            rustfmt
          ];
        };
      }
    ) // {
      # NixOS module
      nixosModules.default = import ./module.nix;

      # Alias for convenience
      nixosModules.hust-network-login = self.nixosModules.default;

      # Overlay for easy integration
      overlays.default = final: prev: {
        hust-network-login = self.packages.${final.system}.default;
      };
    };
}
