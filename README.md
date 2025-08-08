# HyprYou Nix Flake

A Nix flake for [HyprYou](https://github.com/koeqaife/hyprland-material-you), a Material You themed Hyprland desktop environment.

## Features

- **Material You Design**: Modern, adaptive interface following Google's Material You principles
- **Hyprland Integration**: Built specifically for the Hyprland Wayland compositor
- **Easy Installation**: Multiple installation methods via Nix flakes
- **Modular Dependencies**: Optional components that enhance functionality
- **NixOS & Home Manager Support**: First-class integration with both systems

## Prerequisites

- **Nix with flakes enabled**
- **Hyprland**: Install separately via your preferred method:
  ```bash
  # Via nixpkgs
  nix profile install nixpkgs#hyprland

  # Or add to your system configuration
  programs.hyprland.enable = true;
  ```
- **Wayland support**: Ensure your system supports Wayland

## Quick Start

### Try it out (no installation)

```bash
nix run github:rishabh5321/hypryou-flake
```

### One-line installation

```bash
nix profile install github:rishabh5321/hypryou-flake
```

## Installation Methods

### 1. NixOS System Configuration

Add to your `flake.nix`:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    hypryou.url = "github:rishabh5321/hypryou-flake";
  };

  outputs = { self, nixpkgs, hypryou, ... }: {
    nixosConfigurations.your-hostname = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        hypryou.nixosModules.default
        {
          # Enable HyprYou
          services.hypryou.enable = true;

          # Enable Hyprland (required)
          programs.hyprland.enable = true;

          # Optional: Add extra packages to HyprYou environment
          services.hypryou.extraPackages = with pkgs; [
            firefox
            vscode
            # Add your preferred applications
          ];
        }
      ];
    };
  };
}
```

### 2. Home Manager

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    hypryou.url = "github:rishabh5321/hypryou-flake";
  };

  outputs = { self, nixpkgs, home-manager, hypryou, ... }: {
    homeConfigurations.your-username = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      modules = [
        hypryou.homeManagerModules.default
        {
          programs.hypryou.enable = true;

          # Make sure Hyprland is available
          home.packages = with pkgs; [
            hyprland
          ];
        }
      ];
    };
  };
}
```

### 3. Direct Package Installation

Add to your system/home configuration:

```nix
{
  inputs.hypryou.url = "github:rishabh5321/hypryou-flake";

  # In configuration.nix
  environment.systemPackages = [
    inputs.hypryou.packages.${system}.default
  ];

  # Or in home.nix
  home.packages = [
    inputs.hypryou.packages.${system}.default
  ];
}
```

## Usage

### Starting HyprYou

1. **From Display Manager**: Look for "HyprYou" in your display manager (GDM, SDDM, etc.)
2. **From Terminal**: Run `hypryou-start`
3. **Direct Launch**: Run `hypryou` command

⚠️ **Important**: Select "HyprYou" from your display manager, not "Hyprland". HyprYou provides its own configured Hyprland session.

### Configuration

HyprYou will create configuration files in:
- `~/.config/hypryou/` - Main configuration
- `~/.config/hypr/` - Hyprland configuration (managed by HyprYou)

### Key Bindings

HyprYou comes with pre-configured keybindings. Check the configuration files or run `hypryou --help` for details.

## Optional Dependencies

These packages enhance HyprYou's functionality but aren't required:

- **hyprsunset**: Automatic blue light filtering
- **cliphist**: Clipboard history manager

Enable them by overriding the package:

```nix
let
  hypryou-full = inputs.hypryou.packages.${system}.default.override {
    hyprsunset = pkgs.hyprsunset;
    cliphist = pkgs.cliphist;
  };
in {
  environment.systemPackages = [ hypryou-full ];
}
```

## Development

### Development Shell

```bash
git clone https://github.com/rishabh5321/hypryou-flake.git
cd hypryou-flake
nix develop
```

This provides all build dependencies for developing HyprYou.

### Building Locally

```bash
# Build the package
nix build .#default

# Test run
nix run .#default
```

### Contributing

1. Fork this repository
2. Create your feature branch
3. Make changes and test with `nix build`
4. Ensure it works with `nix run .#default`
5. Submit a pull request

## Troubleshooting

### Common Issues

**"HyprYou not appearing in display manager"**
- Ensure the package is installed system-wide, not just in user profile
- Check `/run/current-system/sw/share/wayland-sessions/` for `hypryou.desktop`

**"Command not found: hypryou"**
- Make sure the package is in your PATH
- Try `nix profile install github:rishabh5321/hypryou-flake`

**"Hyprland not starting"**
- Ensure Hyprland is installed separately
- Check GPU drivers support Wayland
- Verify user is in `video` group: `groups $USER`

**"Black screen or crashes"**
- Check logs: `journalctl -u display-manager`
- Try starting from terminal: `hypryou-start`
- Ensure all dependencies are available

### Debug Mode

Run with debug output:
```bash
HYPRYOU_DEBUG=1 hypryou-start
```

### Getting Help

- Check logs: `journalctl --user -u hypryou`
- Original project issues: [HyprYou GitHub Issues](https://github.com/koeqaife/hyprland-material-you/issues)
- Nix-specific issues: Create an issue in this repository

## System Requirements

- **OS**: Linux (NixOS recommended)
- **Display**: Wayland-compatible GPU drivers
- **Memory**: 4GB+ RAM recommended
- **Storage**: ~2GB for full installation

## Architecture Support

Currently tested on:
- x86_64-linux ✅
- aarch64-linux ⚠️ (may work, untested)

## License

This flake packaging is released under GPL-3.0+, same as the original HyprYou project.

- **HyprYou**: [GPL-3.0+](https://github.com/koeqaife/hyprland-material-you/blob/main/LICENSE)
- **This flake**: GPL-3.0+

## Related Projects

- [HyprYou](https://github.com/koeqaife/hyprland-material-you) - Original project
- [Hyprland](https://github.com/hyprwm/Hyprland) - Wayland compositor
- [Material You](https://m3.material.io/) - Design system

## Acknowledgments

- [@koeqaife](https://github.com/koeqaife) - Original HyprYou creator
- [Hyprland team](https://github.com/hyprwm/Hyprland) - Amazing Wayland compositor
- NixOS community - For the excellent packaging ecosystem
