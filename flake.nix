{
  description = "Flake to package ZorinOS/zorin-desktop-themes and provide a home-manager module to expose them to GNOME";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
  };

  outputs = { self, nixpkgs, home-manager, ... }:
    let
      systems = [ "x86_64-linux" ];
    in
    {
      # 为每个 system 构建一个包含所有 themes/icons 的包
      packages = builtins.listToAttrs (map (system:
        let
          pkgs = import nixpkgs { inherit system; };
        in {
          name = system;
          value = pkgs.stdenv.mkDerivation {
            pname = "zorin-desktop-themes";
            version = "master";
            # 开发时使用 fetchTarball 便于不需要事先知道 sha256。生产建议固定 rev + sha256。
            src = builtins.fetchTarball {
              url = "https://github.com/ZorinOS/zorin-desktop-themes/archive/refs/heads/master.tar.gz";
            };
            nativeBuildInputs = [ pkgs.glib ];
            buildPhase = "true";
            installPhase = ''
              mkdir -p $out/share/themes $out/share/icons $out/share/zorin-desktop-themes

              # 复制 repo 中明显的 themes/icons 目录
              if [ -d "$src/themes" ]; then
                cp -r "$src"/themes/* $out/share/themes/ 2>/dev/null || true
              fi
              if [ -d "$src/icons" ]; then
                cp -r "$src"/icons/* $out/share/icons/ 2>/dev/null || true
              fi

              # 一些主题可能位于顶级文件夹中（含 gtk-3.0/gtk-4.0 或 index.theme）
              for d in "$src"/*; do
                [ -e "$d" ] || continue
                if [ -d "$d/gtk-3.0" ] || [ -d "$d/gtk-4.0" ] || [ -f "$d/index.theme" ]; then
                  cp -r "$d" $out/share/themes/ 2>/dev/null || true
                fi
                # 有些图标文件夹也可能以类似方式出现（带 index.theme）
                if [ -f "$d/index.theme" ] && [ -d "$d" ]; then
                  cp -r "$d" $out/share/icons/ 2>/dev/null || true
                fi
              done

              # 保留 repo 原始内容供调试/参考
              cp -r "$src"/* $out/share/zorin-desktop-themes/ 2>/dev/null || true
            '';
            meta = with pkgs.lib; {
              description = "Packaged Zorin desktop themes for user-level installation via Home Manager";
              license = licenses.gpl2;
              platforms = platforms.linux;
            };
          };
        }) systems);

      # 导出 home-manager module，用户可以通过 home-manager modules 导入
      homeManagerModules.zorin-themes = (import ./modules/zorin-themes.nix {
        inherit (builtins) ;
      });
    };
}
