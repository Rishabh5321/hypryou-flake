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
, xdg-desktop-portal-hyprland ? null
, xdg-dbus-proxy ? null
, greetd ? null
, hyprland ? null
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
  pname = "hypryou";
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

  buildInputs =
    let
      # Define base dependencies that should always be available
      baseDeps = [
        gtk4
        cairo
        dbus
        dbus-glib
        networkmanager
        upower
        polkit
        pythonEnv
        xdg-utils
        xdg-desktop-portal
        xdg-desktop-portal-gtk
      ];

      # Optional dependencies - only include if they're valid derivations
      optionalDeps = lib.filter (dep: dep != null && lib.isDerivation dep) [
        hyprland
        xdg-desktop-portal-hyprland
        xdg-dbus-proxy
        greetd
        hyprsunset
        cliphist
      ];
    in
    baseDeps ++ optionalDeps;

  postPatch = ''
    # Make build scripts executable
    chmod +x hypryou/build.sh || true
    chmod +x build/build.sh || true
    chmod +x hypryou-assets/configs/hyprland/scripts/xdg.sh || true

    # Patch shebang lines in scripts
    find . -type f -name "*.sh" -exec sed -i \
      -e "s|#!/bin/bash|#!${stdenv.shell}|g" \
      -e "s|#!/usr/bin/env bash|#!${stdenv.shell}|g" {} +

    # Fix hardcoded paths in Python files
    find . -name "*.py" -type f -exec sed -i \
      -e "s|/usr/lib/hypryou|$out/lib/hypryou|g" \
      -e "s|/usr/share/hypryou|$out/share/hypryou-assets|g" \
      -e "s|/usr/bin/hypryou|$out/bin/hypryou|g" {} +

    # Fix any hardcoded paths in shell scripts
    find . -name "*.sh" -type f -exec sed -i \
      -e "s|/usr/lib/hypryou|$out/lib/hypryou|g" \
      -e "s|/usr/share/hypryou|$out/share/hypryou-assets|g" \
      -e "s|/usr/bin/hypryou|$out/bin/hypryou|g" {} +
  '';

  buildPhase = ''
    runHook preBuild

    echo "Building Cython components..."
    if [ -d "hypryou/utils_cy" ]; then
      cd hypryou/utils_cy
      if ls *.pyx 1> /dev/null 2>&1; then
        for pyx_file in *.pyx; do
          echo "Compiling $pyx_file..."
          cython -3 "$pyx_file"
        done

        # Compile C extensions
        for c_file in *.c; do
          if [ -f "$c_file" ]; then
            so_name="''${c_file%.c}.so"
            echo "Building $so_name..."
            gcc -shared -fPIC $(python3-config --includes) -o "$so_name" "$c_file"
          fi
        done
      fi
      cd ../..
    fi

    # Build using the project's build script if it exists
    if [ -f "build/build.sh" ]; then
      echo "Running project build script..."
      cd build
      bash ./build.sh || echo "Build script failed, continuing..."
      cd ..
    fi

    runHook postBuild
  '';

  installPhase = ''
        runHook preInstall

        # Create directory structure
        mkdir -p $out/{lib/hypryou,share,bin}
        mkdir -p $out/share/{wayland-sessions,applications}

        # Install Python modules
        if [ -d "hypryou" ]; then
          cp -r hypryou/* $out/lib/hypryou/
          # Make sure compiled extensions are executable
          find $out/lib/hypryou -name "*.so" -exec chmod +x {} \;
        fi

        # Install assets
        if [ -d "hypryou-assets" ]; then
          cp -r hypryou-assets $out/share/
        fi

        # Install built binaries if they exist
        for binary in hypryouctl hypryou-start hypryou-crash-dialog; do
          if [ -f "build/$binary" ]; then
            install -Dm755 "build/$binary" "$out/bin/"
          fi
        done

        # Create main executable if it doesn't exist
        if [ ! -f "$out/bin/hypryou" ]; then
          cat > $out/bin/hypryou << 'EOF'
    #!/usr/bin/env bash
    export HYPRYOU_LIB_DIR="$HYPRYOU_LIB_DIR"
    export HYPRYOU_SHARE_DIR="$HYPRYOU_SHARE_DIR"
    exec python3 -m hypryou "$@"
    EOF
          chmod +x $out/bin/hypryou
        fi

        # Install desktop session file
        if [ -f "assets/hypryou.desktop" ]; then
          install -Dm644 "assets/hypryou.desktop" "$out/share/wayland-sessions/"
        else
          # Create a basic desktop file if it doesn't exist
          cat > $out/share/wayland-sessions/hypryou.desktop << 'EOF'
    [Desktop Entry]
    Name=HyprYou
    Comment=Material You themed Hyprland desktop environment
    Exec=hypryou-start
    Type=Application
    EOF
        fi

        runHook postInstall
  '';

  postFixup = ''
    # Wrap all executables
    for bin in $out/bin/*; do
      if [ -x "$bin" ]; then
        wrapProgram "$bin" \
          --prefix PYTHONPATH : "$out/lib/hypryou:${pythonEnv}/${pythonEnv.sitePackages}" \
          --prefix PATH : "${lib.makeBinPath (lib.filter (dep: dep != null && lib.isDerivation dep) [
            xdg-utils
            dart-sass
            networkmanager
            upower
            python3
            hyprland
            hyprsunset
            cliphist
          ])}" \
          --set GI_TYPELIB_PATH "${lib.makeSearchPath "lib/girepository-1.0" [
            gtk4
            gobject-introspection
          ]}" \
          --set HYPRYOU_LIB_DIR "$out/lib/hypryou" \
          --set HYPRYOU_SHARE_DIR "$out/share/hypryou-assets"
      fi
    done
  '';

  meta = with lib; {
    description = "Material You themed Hyprland desktop environment";
    longDescription = ''
      HyprYou is a Material You themed desktop environment built on top of Hyprland.
      It provides a cohesive, modern interface following Google's Material You design principles.
    '';
    homepage = "https://github.com/koeqaife/hyprland-material-you";
    license = licenses.gpl3Plus;
    platforms = platforms.linux;
    maintainers = [ ];
    mainProgram = "hypryou";
  };
}
