{ config, pkgs, lib, ... }:

let
  cfg = config.programs.zorin-themes;
in
{
  options.programs.zorin-themes = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable symlinking Zorin themes/icons into ~/.local/share for GNOME.";
    };

    package = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Path to the packaged zorin-desktop-themes store path. If null, no symlinks are created.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.activation.zorin-themes = {
      text = "Symlink Zorin themes/icons to ~/.local/share for GNOME discovery";
      script = lib.template ''
        echo "Activating zorin-themes..."

        mkdir -p "$HOME/.local/share/themes" "$HOME/.local/share/icons"

        if [ -z "${toString ${cfg.package}}" ] || [ "${toString ${cfg.package}}" = "null" ]; then
          echo "programs.zorin-themes.package is not set; nothing to symlink."
          exit 0
        fi

        src=${toString ${cfg.package}}
        if [ ! -e "$src" ]; then
          echo "Specified package path $src does not exist."
          exit 1
        fi

        # Symlink theme directories
        if [ -d "$src/share/themes" ]; then
          for p in "$src"/share/themes/*; do
            [ -e "$p" ] || continue
            ln -sfn "$p" "$HOME/.local/share/themes/$(basename "$p")"
          done
        fi

        # Symlink icon themes
        if [ -d "$src/share/icons" ]; then
          for p in "$src"/share/icons/*; do
            [ -e "$p" ] || continue
            ln -sfn "$p" "$HOME/.local/share/icons/$(basename "$p")"
          done
        fi

        echo "Zorin themes/icons linked into ~/.local/share."
      '';
    };
  };
}
