{ config, pkgs, lib, ... }:

{
  options.programs.zorin-icons = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Enable symlinking Zorin icon themes into ~/.local/share/icons for GNOME.
      '';
    };

    package = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        Path to the packaged Zorin icon themes. If null, no symlinks will be created.
      '';
    };
  };

  config = lib.mkIf config.programs.zorin-icons.enable {
    home.activation.zorin-icons = ''
      echo "Activating Zorin icon themes..."

      # Ensure required directory exists
      mkdir -p "$HOME/.local/share/icons"

      # Validate the source package path
      if [ -z "${builtins.toString config.programs.zorin-icons.package}" ] || \
         [ "${builtins.toString config.programs.zorin-icons.package}" = "null" ]; then
        echo "Error: programs.zorin-icons.package is not set. Nothing to symlink."
        exit 0
      fi

      src=${builtins.toString config.programs.zorin-icons.package}
      if [ ! -e "$src" ]; then
        echo "Error: Specified package path $src does not exist."
        exit 1
      fi

      # Link icon directories
      if [ -d "$src/share/icons" ]; then
        for icon_dir in "$src/share/icons/"*; do
          [ -e "$icon_dir" ] || continue
          ln -sfn "$icon_dir" "$HOME/.local/share/icons/$(basename "$icon_dir")"
        done
      fi

      echo "Zorin icon themes successfully linked to ~/.local/share/icons."
    '';
  };
}
