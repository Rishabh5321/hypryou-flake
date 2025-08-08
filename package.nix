{ lib
, stdenv
, fetchFromGitHub
, python3
, gtk4
, gobject-introspection
, cairo
, dbus
, dbus-glib
, networkmanager
, upower
, polkit
, dart-sass
, xdg-utils
, xdg-desktop-portal
, xdg-desktop-portal-gtk
, xdg-desktop-portal-hyprland
, xdg-dbus-proxy
, greetd
, hyprland
, hyprsunset ? null
, cliphist ? null
, pkg-config
, wrapGAppsHook4
, makeWrapper
}:

let
  pythonEnv = python3.withPackages (ps: with ps; [
    pygobject3
    pillow
    pycairo
    cython
    setuptools
  ]);

in
stdenv.mkDerivation rec {
  pname = "hyprland-material-you";
  version = "unstable-2024-01-01";

  src = fetchFromGitHub {
    owner = "koeqaife";
    repo = "hyprland-material-you";
    rev = "b0a1b13e94bfdd86188594f9f9c43cd37398ac71";
    sha256 = "sha256-c7NV9/H5fuLx95ofVncDcGugLiQZ4AuqTp9APOu8TtQ=";
  };

  nativeBuildInputs = [
    pkg-config
    wrapGAppsHook4
    makeWrapper
    pythonEnv
    dart-sass
    gobject-introspection
  ];

  buildInputs = [
    gtk4
    cairo
    dbus
    dbus-glib
    networkmanager
    upower
    polkit
    pythonEnv
    hyprland
    xdg-utils
    xdg-desktop-portal
    xdg-desktop-portal-gtk
    xdg-desktop-portal-hyprland
    xdg-dbus-proxy
    greetd
  ] ++ lib.optionals (hyprsunset != null) [ hyprsunset ]
  ++ lib.optionals (cliphist != null) [ cliphist ];

  postPatch = ''
    # Make build scripts executable
    chmod +x hypryou/build.sh
    chmod +x build/build.sh
    chmod +x hypryou-assets/configs/hyprland/scripts/xdg.sh

    # Patch shebang lines only if they exist
    for file in hypryou/build.sh build/build.sh hypryou-assets/configs/hyprland/scripts/xdg.sh; do
      if grep -q '^#!/bin/bash' "$file"; then
        substituteInPlace "$file" --replace '#!/bin/bash' '#!${stdenv.shell}'
      elif grep -q '^#!/usr/bin/env bash' "$file"; then
        substituteInPlace "$file" --replace '#!/usr/bin/env bash' '#!${stdenv.shell}'
      fi
    done

    # Fix paths in Python files
    find . -name "*.py" -type f -exec sed -i \
      -e "s|/usr/lib/hypryou|$out/lib/hypryou|g" \
      -e "s|/usr/share/hypryou|$out/share/hypryou|g" \
      -e "s|/usr/bin/hypryou|$out/bin/hypryou|g" {} +
  '';

  buildPhase = ''
    runHook preBuild

    echo "Building Cython components..."
    cd hypryou/utils_cy
    cython -3 *.pyx
    gcc -shared -fPIC $(python3-config --includes) -o levenshtein.so levenshtein.c
    gcc -shared -fPIC $(python3-config --includes) -o helpers.so helpers.c
    cd ../..

    echo "Building main application..."
    cd build
    ./build.sh
    cd ..

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    # Create directories
    mkdir -p $out/lib/hypryou
    mkdir -p $out/share/hypryou
    mkdir -p $out/bin
    mkdir -p $out/share/wayland-sessions

    # Install Python modules
    cp -r hypryou/* $out/lib/hypryou/
    chmod +x $out/lib/hypryou/utils_cy/*.so

    # Install assets
    cp -r hypryou-assets $out/share/

    # Install binaries (from build directory)
    install -Dm755 build/hypryouctl $out/bin/ || true
    install -Dm755 build/hypryou-start $out/bin/ || true
    install -Dm755 build/hypryou-crash-dialog $out/bin/ || true

    # Install desktop file
    install -Dm644 assets/hypryou.desktop $out/share/wayland-sessions/ || true

    runHook postInstall
  '';

  postFixup = ''
    # Wrap binaries
    for bin in $out/bin/*; do
      wrapProgram $bin \
        --prefix PYTHONPATH : "$out/lib/hypryou:${pythonEnv}/${pythonEnv.sitePackages}" \
        --prefix PATH : "${lib.makeBinPath ([
          hyprland
          xdg-utils
          dart-sass
          networkmanager
          upower
        ] ++ lib.optionals (hyprsunset != null) [ hyprsunset ]
          ++ lib.optionals (cliphist != null) [ cliphist ])}" \
        --set GI_TYPELIB_PATH "${lib.makeSearchPath "lib/girepository-1.0" [
          gtk4
          gobject-introspection
        ]}" \
        --set HYPRYOU_LIB_DIR "$out/lib/hypryou" \
        --set HYPRYOU_SHARE_DIR "$out/share/hypryou-assets"
    done
  '';

  meta = with lib; {
    description = "Material You themed Hyprland desktop environment";
    homepage = "https://github.com/koeqaife/hyprland-material-you";
    license = licenses.gpl3Plus;
    platforms = platforms.linux;
    maintainers = [ ];
  };
}
