{
  description = "Flake to package ZorinOS/zorin-desktop-themes and ZorinOS/zorin-icon-themes, and provide home-manager modules.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
  };

  outputs = { self, nixpkgs, home-manager, ... }:
    let
      systems = [ "x86_64-linux" ];
    in
    {
      # 1. 打包 zorin-desktop-themes
      packages = builtins.listToAttrs (map (system:
        let
          pkgs = import nixpkgs { inherit system; };
        in {
          name = system;
          value = pkgs.stdenv.mkDerivation {
            pname = "zorin-desktop-themes";
            version = "master";
            src = builtins.fetchTarball {
              url = "https://github.com/ZorinOS/zorin-desktop-themes/archive/refs/heads/master.tar.gz";
              sha256 = "1n9rhayxv4rh3l86hqxqkpc3dayf9i91mhx4pfivd04kx6xd6aqm";
            };
            nativeBuildInputs = [ pkgs.glib ];
            buildPhase = "true";
            installPhase = ''
              mkdir -p $out/share/themes $out/share/icons $out/share/zorin-desktop-themes

              if [ -d "$src/themes" ]; then
                cp -r "$src"/themes/* $out/share/themes/ 2>/dev/null || true
              fi
              if [ -d "$src/icons" ]; then
                cp -r "$src"/icons/* $out/share/icons/ 2>/dev/null || true
              fi

              for d in "$src"/*; do
                [ -e "$d" ] || continue
                if [ -d "$d/gtk-3.0" ] || [ -d "$d/gtk-4.0" ] || [ -f "$d/index.theme" ]; then
                  cp -r "$d" $out/share/themes/ 2>/dev/null || true
                fi
                if [ -f "$d/index.theme" ] && [ -d "$d" ]; then
                  cp -r "$d" $out/share/icons/ 2>/dev/null || true
                fi
              done

              cp -r "$src"/* $out/share/zorin-desktop-themes/ 2>/dev/null || true
            '';
            meta = with pkgs.lib; {
              description = "Packaged Zorin desktop themes for user-level installation via Home Manager";
              license = licenses.gpl2;
              platforms = platforms.linux;
            };
          };
        }) systems);

      # 2. 打包 zorin-icon-themes
      packages-icon = builtins.listToAttrs (map (system:
        let
          pkgs = import nixpkgs { inherit system; };
        in {
          name = system;
          value = pkgs.stdenv.mkDerivation {
            pname = "zorin-icon-themes";
            version = "master";
            src = builtins.fetchTarball {
              url = "https://github.com/ZorinOS/zorin-icon-themes/archive/refs/heads/master.tar.gz";
              sha256 = "0a4q5pdnfykh1bifv44y22qbd98n0am536mgfazs9g8m5nis085b";
            };
            nativeBuildInputs = [ pkgs.glib ];
            buildPhase = "true";
            installPhase = ''
              mkdir -p $out/share/icons $out/share/zorin-icon-themes

              if [ -d "$src/icons" ]; then
                cp -r "$src"/icons/* $out/share/icons/ 2>/dev/null || true
              fi

              for d in "$src"/*; do
                [ -e "$d" ] || continue
                if [ -f "$d/index.theme" ] && [ -d "$d" ]; then
                  cp -r "$d" $out/share/icons/ 2>/dev/null || true
                fi
              done

              cp -r "$src"/* $out/share/zorin-icon-themes/ 2>/dev/null || true
            '';
            meta = with pkgs.lib; {
              description = "Packaged Zorin icon themes for user-level installation via Home Manager";
              license = licenses.gpl2;
              platforms = platforms.linux;
            };
          };
        }) systems);

      # 3. 导出 home-manager modules
      homeManagerModules = {
        zorin-themes = import ./modules/zorin-themes.nix;
        zorin-icons  = import ./modules/zorin-icons.nix;
      };
    };
}
