{
  description = "Flake that packages ZorinOS/zorin-desktop-themes and exposes a home-manager module";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
  };

  outputs = { self, nixpkgs, home-manager, ... }:
    let
      systems = [ "x86_64-linux" ];
      lib = import nixpkgs { system = "x86_64-linux"; }.lib;
    in
    {
      # 为每个 system 构建一个包含所有 themes/icons 的包
      packages = lib.listToAttrs (map (system:
        let
          pkgs = import nixpkgs { inherit system; };
        in {
          name = system;
          value = pkgs.stdenv.mkDerivation {
            pname = "zorin-desktop-themes";
            version = "master"; # 可替换为 tag/commit
            # 开发便利：使用 builtins.fetchTarball，这样示例无需事先知道 sha256。
            # 生产使用建议把 rev 固定并用 fetchFromGitHub + 固定 sha256。
            src = builtins.fetchTarball {
              url = "https://github.com/ZorinOS/zorin-desktop-themes/archive/refs/heads/master.tar.gz";
            };
            buildInputs = [ pkgs.glib ];
            buildPhase = ''
              # no build step; we're just packaging files
              true
            '';
            installPhase = ''
              mkdir -p $out/share/themes $out/share/icons
              # 1) 如果仓库里有 top-level themes/ icons/ 目录，复制其内容
              if [ -d "$src/themes" ]; then
                cp -r "$src"/themes/* $out/share/themes/ 2>/dev/null || true
              fi
              if [ -d "$src/icons" ]; then
                cp -r "$src"/icons/* $out/share/icons/ 2>/dev/null || true
              fi

              # 2) 有些 gtk 主题可能自身就在顶级目录（带 gtk-3.0/gtk-4.0 文件夹）
              for d in "$src"/*; do
                if [ -d "$d" ]; then
                  base=$(basename "$d")
                  case "$base" in themes|icons) continue ;; esac
                  if [ -d "$d/gtk-3.0" ] || [ -d "$d/gtk-4.0" ] || [ -f "$d/index.theme" ]; then
                    cp -r "$d" $out/share/themes/ 2>/dev/null || true
                  fi
                fi
              done

              # 3) 保留 repo 原始元数据（可选）
              mkdir -p $out/share/zorin-desktop-themes
              cp -r "$src"/* $out/share/zorin-desktop-themes/ 2>/dev/null || true
            '';
            meta = with pkgs.lib; {
              description = "Zorin desktop themes packaged for local use";
              license = licenses.gpl2;
              platforms = platforms.linux;
            };
          };
        }) systems);

      # home-manager module 输出：用户可以把这个 module 加入自己的 home.nix
      homeManagerModules = {
        zorin-themes = home-manager.lib.makeModule {
          cfg = { allowUnfree = false; }; # placeholder
          name = "zorin-themes";
          meta = {
            description = "Home Manager module to symlink packaged themes/icons into ~/.local/share";
            maintainers = with (import nixpkgs { system = "x86_64-linux"; }).lib.maintainers; [];
          };
          imports = [];
          options = {
            programs.zorin-themes = {
              enable = home-manager.lib.mkOption {
                type = home-manager.lib.types.bool;
                default = false;
                description = "Enable zorin-themes symlink activation.";
              };
              # 用户需要将这个 option 指向上面 packages 输出之一，例如:
              # inputs.zorin-flake.packages.x86_64-linux.zorin-desktop-themes
              package = home-manager.lib.mkOption {
                type = home-manager.lib.types.nullOr home-manager.lib.types.path;
                default = null;
                description = "Path to the zorin themes package (a store path). If set, files will be symlinked from here into ~/.local/share.";
              };
            };
          };
          config = { config, pkgs, lib, ... }: let
            cfg = config.programs."zorin-themes";
          in {
            # activation script：在 home-manager activate 时运行，创建目标目录并建立 symlink
            home.activation.zorin-themes = lib.mkIf cfg.enable {
              text = "Install Zorin themes and icons into ~/.local/share for GNOME to discover";
              script = ''
                echo "Zorin themes activation running..."
                mkdir -p "$HOME/.local/share/themes" "$HOME/.local/share/icons"

                if [ -z "${toString cfg.package}" ] || [ "${toString cfg.package}" = "null" ]; then
                  echo "programs.zorin-themes.package is not set; skipping symlink step"
                  exit 0
                fi

                src=${toString cfg.package}
                if [ ! -e "$src" ]; then
                  echo "package path $src doesn't exist"
                  exit 1
                fi

                # Symlink each theme dir
                if [ -d "$src/share/themes" ]; then
                  for p in "$src"/share/themes/*; do
                    [ -e "$p" ] || continue
                    ln -sfn "$p" "$HOME/.local/share/themes/$(basename "$p")"
                  done
                fi

                # Symlink each icon theme
                if [ -d "$src/share/icons" ]; then
                  for p in "$src"/share/icons/*; do
                    [ -e "$p" ] || continue
                    ln -sfn "$p" "$HOME/.local/share/icons/$(basename "$p")"
                  done
                fi

                echo "Zorin themes symlinked to ~/.local/share"
              '';
            };
          };
        };
      };
    };
}
