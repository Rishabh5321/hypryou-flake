# HyprYou Nix Flake

A Nix flake for [HyprYou](https://github.com/koeqaife/hyprland-material-you), a Material You themed Hyprland desktop environment.

## Quick Start

### Using with `nix run`

```bash
# Run directly from GitHub
nix run github:yourusername/hypryou-flake

# Or clone and run locally
git clone https://github.com/yourusername/hypryou-flake.git
cd hypryou-flake
nix run .
```

### Using in your Nix configuration

#### With NixOS

Add to your `flake.nix` inputs:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    hypryou.url = "github:yourusername/hypryou-flake";
  };

  outputs = { self, nixpkgs, hypryou, ... }: {
    nixosConfigurations.your-hostname = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        hypryou.nixosModules.default
        {
          services.hypryou.enable = true;
          # Optional: add extra packages
          services.hypryou.extraPackages = with pkgs; [
            # Add any additional packages you want available in HyprYou
          ];
        }
      ];
    };
  };
}
```

#### With Home Manager

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    hypryou.url = "github:yourusername/hypryou-flake";
  };

  outputs = { self, nixpkgs, home-manager, hypryou, ... }: {
    homeConfigurations.your-username = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      modules = [
        hypryou.homeManagerModules.default
        {
          programs.hypryou.enable = true;
        }
      ];
    };
  };
}
```

#### Manual Installation

Add to your system packages:

```nix
{
  inputs.hypryou.url = "github:yourusername/hypryou-flake";

  # In your configuration.nix or home.nix
  environment.systemPackages = [
    inputs.hypryou.packages.${system}.default
  ];
}
```

## Usage

1. **Start HyprYou**: After installation, you should see "HyprYou" as an option in your display manager
2. **Launch from terminal**: Run `hypryou-start` to start the desktop environment
3. **Configuration**: HyprYou configuration files will be located in your home directory

## Dependencies

The flake automatically handles all dependencies including:

- Hyprland
- Python 3 with required packages
- GTK4
- Various system utilities

Optional dependencies (set to null by default, can be overridden):
- `hyprsunset` - For sunset/sunrise lighting
- `cliphist` - For clipboard history

## Customization

### Override Dependencies

```nix
# In your flake.nix
let
  hypryou-custom = hypryou.packages.${system}.default.override {
    hyprsunset = pkgs.hyprsunset;
    cliphist = pkgs.cliphist;
  };
in
{
  environment.systemPackages = [ hypryou-custom ];
}
```

### Development

To work on HyprYou development:

```bash
git clone https://github.com/yourusername/hypryou-flake.git
cd hypryou-flake
nix develop
```

This provides a development shell with all necessary build dependencies.

## Troubleshooting

### Common Issues

1. **Display Manager**: Make sure you're selecting "HyprYou" from your display manager, not "Hyprland"
2. **Permissions**: Ensure your user is in necessary groups for graphics and input devices
3. **Wayland**: Make sure your system supports Wayland

### Logs

Check logs with:
```bash
journalctl -u display-manager
# or
journalctl --user -u hypryou
```

## Contributing

1. Fork this repository
2. Make your changes
3. Test with `nix build` and `nix run`
4. Submit a pull request

## License

This flake packaging is released under the same license as HyprYou (GPL-3.0+).

Original project: https://github.com/koeqaife/hyprland-material-you
