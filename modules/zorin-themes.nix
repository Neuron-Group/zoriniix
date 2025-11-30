{ config, pkgs, lib, ... }:

{
  options.programs.zorin-themes = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Enable symlinking Zorin themes/icons into ~/.local/share for GNOME.
      '';
    };

    package = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        Path to the packaged Zorin desktop themes. If null, no symlinks will be created.
      '';
    };
  };

  config = lib.mkIf config.programs.zorin-themes.enable {
    home.activation.zorin-themes = ''
      echo "Activating Zorin themes/icons..."

      # Ensure required directories exist
      mkdir -p "$HOME/.local/share/themes" "$HOME/.local/share/icons"

      # Validate the source package path
      if [ -z "${builtins.toString config.programs.zorin-themes.package}" ] || \
         [ "${builtins.toString config.programs.zorin-themes.package}" = "null" ]; then
        echo "Error: programs.zorin-themes.package is not set. Nothing to symlink."
        exit 0
      fi

      src=${builtins.toString config.programs.zorin-themes.package}
      if [ ! -e "$src" ]; then
        echo "Error: Specified package path $src does not exist."
        exit 1
      fi

      # Link theme directories
      if [ -d "$src/share/themes" ]; then
        for theme_dir in "$src/share/themes/"*; do
          [ -e "$theme_dir" ] || continue
          ln -sfn "$theme_dir" "$HOME/.local/share/themes/$(basename "$theme_dir")"
        done
      fi

      # Link icon directories
      if [ -d "$src/share/icons" ]; then
        for icon_dir in "$src/share/icons/"*; do
          [ -e "$icon_dir" ] || continue
          ln -sfn "$icon_dir" "$HOME/.local/share/icons/$(basename "$icon_dir")"
        done
      fi

      echo "Zorin themes/icons successfully linked to ~/.local/share."
    '';
  };
}
