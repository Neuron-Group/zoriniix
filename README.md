# zorin-nix-flake

This flake packages the `ZorinOS/zorin-desktop-themes` repository and provides
a Home Manager module to symlink the themes and icons into `~/.local/share`
so that GNOME Settings can discover them.

## What this repo provides

- `flake.nix` — builds a package (`zorin-desktop-themes`) that contains the
  themes and icons from the upstream repository.
- `modules/zorin-themes.nix` — a Home Manager module that, when enabled, will
  symlink themes/icons from the package into `~/.local/share/themes` and
  `~/.local/share/icons`.
- Example usage is shown below.

## How to use

1. Add this flake as an input in your own flake:

```nix
inputs = {
  nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05";
  home-manager.url = "github:nix-community/home-manager";
  zorin-themes.url = "github:yourname/zorin-nix-flake"; # replace with your fork/url
};
```

2. Import the module and point `programs.zorin-themes.package` to the package
   output from this flake. Example snippet for `flake.outputs.homeConfigurations`:

```nix
# inside your flake outputs...
homeConfigurations.<your-user> = home-manager.lib.homeManagerConfiguration {
  pkgs = import nixpkgs { system = "x86_64-linux"; };
  modules = [
    zorin-themes.homeManagerModules.zorin-themes
    # ...your other home-manager modules
  ];
  configuration = {
    programs.zorin-themes = {
      enable = true;
      # point to the package built by this flake for your system:
      package = zorin-themes.packages."x86_64-linux";
      # if your flake exposes another path, use that store path
    };
  };
};
```

3. Rebuild your home-manager configuration:
```
home-manager switch --flake .#<your-user>@<host>
```

4. Restart GNOME shell or log out/in. The themes/icons should now appear in
   GNOME Settings -> Appearance.

## Notes and suggestions

- Currently the flake fetches `master` via `builtins.fetchTarball` for development
  convenience. For reproducibility you should pin to a specific rev and use
  `pkgs.fetchFromGitHub` with a fixed `sha256`.
- You can adapt the flake to produce separate packages per-theme if you want
  to install only selected themes.
- This module installs themes per-user (under `~/.local/share`). If you prefer
  system-wide installation, install the generated package through your
  NixOS configuration (systemPackages) or write a NixOS module.
