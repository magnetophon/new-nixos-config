{
  description = "NixOS configurations for nixframe, nixframe-rt and pronix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    musnix.url = "github:musnix/musnix";
    deploy-rs.url = "github:serokell/deploy-rs";
  };

  outputs = inputs@{ self, nixpkgs, nixos-hardware, musnix, deploy-rs, ... }:
    let
      system = "x86_64-linux";
    in
    {
      nixosConfigurations.nixframe = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ./hosts/nixframe/default.nix
          ./modules/common.nix
          ./modules/laptop.nix
          ./modules/non-rt.nix
          nixos-hardware.nixosModules.framework-12th-gen-intel
          musnix.nixosModules.musnix
        ];
      };

      nixosConfigurations.nixframe-rt = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ./hosts/nixframe-rt/default.nix
          ./modules/common.nix
          ./modules/laptop.nix
          ./modules/rt.nix
          nixos-hardware.nixosModules.framework-12th-gen-intel
          musnix.nixosModules.musnix
        ];
      };

      nixosConfigurations.pronix = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ./hosts/pronix/default.nix
          ./modules/common.nix
          ./modules/server.nix
        ];
      };

      deploy.nodes.pronix = {
        hostname = "81.206.32.45";
        sshUser = "bart";
        user = "root";
        interactiveSudo = true;
        sshOpts = [ "-p" "511" ];
        remoteBuild = true;
        profiles.system = {
          user = "root";
          path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.pronix;
        };
      };

      checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
    };
}
