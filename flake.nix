{
  description = "HyprYou - Material You themed Hyprland desktop environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        hypryou = pkgs.callPackage ./default.nix {
          # Use hyprland from nixpkgs if available
          hyprland = pkgs.hyprland or null;
          # Pass optional dependencies, they'll be null if not available
          xdg-desktop-portal-hyprland = pkgs.xdg-desktop-portal-hyprland or null;
          xdg-dbus-proxy = pkgs.xdg-dbus-proxy or null;
          greetd = pkgs.greetd or null;
          hyprsunset = pkgs.hyprsunset or null;
          cliphist = pkgs.cliphist or null;
        };

      in
      {
        packages = {
          default = hypryou;
          hypryou = hypryou;
        };

        # For development
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            python3
            python3Packages.pygobject3
            python3Packages.pillow
            python3Packages.pycairo
            python3Packages.cython
            python3Packages.setuptools
            gtk4
            gobject-introspection
            cairo
            dbus
            dbus-glib
            networkmanager
            upower
            polkit
            dart-sass
            pkg-config
          ];
        };

        # NixOS module for easy integration
        nixosModules.default = { config, lib, pkgs, ... }:
          with lib;
          let
            cfg = config.services.hypryou;
          in
          {
            options.services.hypryou = {
              enable = mkEnableOption "HyprYou desktop environment";

              package = mkOption {
                type = types.package;
                default = self.packages.${system}.hypryou;
                description = "The HyprYou package to use";
              };

              extraPackages = mkOption {
                type = types.listOf types.package;
                default = [ ];
                description = "Extra packages to include in HyprYou environment";
              };
            };

            config = mkIf cfg.enable {
              # Enable required services
              services.greetd.enable = mkDefault true;
              programs.hyprland.enable = mkDefault true;

              # Add HyprYou to system packages
              environment.systemPackages = [ cfg.package ] ++ cfg.extraPackages;

              # Ensure required portals are available
              xdg.portal = {
                enable = mkDefault true;
                extraPortals = with pkgs; [
                  xdg-desktop-portal-gtk
                  xdg-desktop-portal-hyprland
                ];
              };

              # Add wayland session
              services.xserver.displayManager.sessionPackages = [ cfg.package ];
            };
          };

        # Home Manager module
        homeManagerModules.default = { config, lib, pkgs, ... }:
          with lib;
          let
            cfg = config.programs.hypryou;
          in
          {
            options.programs.hypryou = {
              enable = mkEnableOption "HyprYou desktop environment";

              package = mkOption {
                type = types.package;
                default = self.packages.${system}.hypryou;
                description = "The HyprYou package to use";
              };
            };

            config = mkIf cfg.enable {
              home.packages = [ cfg.package ];
            };
          };
      });
}
