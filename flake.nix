{
  description = "aerc + cmdline tools + links in ~/.aerc-tools";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ...} @inputs : 
    flake-utils.lib.eachDefaultSystem (system:
  let 
    pkgs = nixpkgs.legacyPackages.${system} ; 
    # pkgs = import nixpkgs { inherit overlays system;} ; 
    aercpython = pkgs.python39.withPackages(p: with p; [p.vobject]);
    proxypython = pkgs.python3.withPackages(p: with p; [
      configobj
      cryptography
      pillow
      pystray
      pywebview
      timeago
      ]);

  in rec {
    packages.aerc-tools-install = pkgs.writeShellScriptBin "aerc-tools-install" ''
        # prepare AERC_TOOLS_BIN
        # ln all our executables there 
        # in configs, we use those in shebang lines
        export AERC_TOOLS_BIN=~/.aerc-tools;
        mkdir -p $AERC_TOOLS_BIN
        rm $AERC_TOOLS_BIN/* 2>/dev/null

        ln -s ${pkgs.bat}/bin/bat $AERC_TOOLS_BIN/bat
        ln -s ${pkgs.less}/bin/less $AERC_TOOLS_BIN/less
        ln -s ${pkgs.gawk}/bin/awk $AERC_TOOLS_BIN/awk
        ln -s ${pkgs.gnused}/bin/sed $AERC_TOOLS_BIN/sed
        ln -s ${pkgs.pandoc}/bin/pandoc $AERC_TOOLS_BIN/pandoc
        ln -s ${pkgs.colordiff}/bin/colordiff $AERC_TOOLS_BIN/colordiff
        ln -s ${pkgs.dante}/bin/socksify $AERC_TOOLS_BIN/socksify
        ln -s ${pkgs.w3m}/bin/w3m $AERC_TOOLS_BIN/w3m
        ln -s ${pkgs.catimg}/bin/catimg $AERC_TOOLS_BIN/catimg
        ln -s ${pkgs.bashInteractive}/bin/bash $AERC_TOOLS_BIN/bash
        ln -s ${aercpython}/bin/python $AERC_TOOLS_BIN/python
        export PATH=$AERC_TOOLS_BIN:$PATH
    '';

    packages.aerc-run = pkgs.writeShellApplication { 
      name = "aerc-run";
      runtimeInputs = with pkgs; [
          bat
          less
          gawk
          gnused
          pandoc
          colordiff
          neovim
          # for socksify: dante
          dante
          w3m
          bashInteractive 
          catimg
          aercpython
          packages.aerc-tools-install
          aerc # overlay added all other runtime deps
          bashInteractive
      ]; 
      text = ''
        #!${pkgs.stdenv.shell}
        aerc-tools-install
        export AERC_TOOLS_BIN=~/.aerc-tools;
        export PATH=$AERC_TOOLS_BIN:$PATH
        aerc "$@"
      '';
    };

    packages.myaerc = pkgs.stdenv.mkDerivation {
        name = "myaerc";
        buildInputs = [
            packages.aerc-run
            pkgs.aerc
            packages.emailproxy-run
        ];
        unpackPhase = "true";
        installPhase = ''
          mkdir -p $out/bin
          cp -r ${pkgs.aerc.out}/* $out/
          find ${packages.aerc-run.out}/
          cp -vr ${packages.aerc-run.out}/bin/aerc-run $out/bin/
          cp -vr ${packages.emailproxy-run}/bin/emailproxy $out/bin/
          mv $out/bin/aerc $out/bin/aerc-internal
          mv $out/bin/aerc-run $out/bin/aerc
        '';
    };

    defaultPackage = packages.myaerc;

    # we want a shell, where all relevant executables, filters etc 
    # are on the path, so we don't need explicit, package-specific 
    # nix-store paths in our config
    devShells.default = pkgs.mkShell {
      nativeBuildInputs = with pkgs; [
          packages.myaerc
      ];

      shellHook = ''
      '';
    };

    packages.emailproxy = pkgs.stdenv.mkDerivation {
        name = "aerc-email-proxy";
        src = pkgs.fetchFromSourcehut {
            owner = "~renerocksai";
            repo = "aerc-oauth2-proxy";
            rev = "master";
            hash = "sha256-z2/QLiaCtNgTJFQKZnHEi1ayb5tzQONFI0dhOqnCoYA=";
            vc = "git";
        };
        buildInputs = [
          proxypython
        ];
        installPhase = ''
          mkdir -p $out/bin
          cp emailproxy.py $out/bin
        '';
    };

    packages.emailproxy-run = pkgs.writeShellApplication { 
      name = "emailproxy";
      runtimeInputs = with pkgs; [
          bashInteractive
          proxypython
          packages.emailproxy
      ]; 
      text = ''
        #!${pkgs.stdenv.shell}
        python ${packages.emailproxy.out}/bin/emailproxy.py "$@"
      '';
    };
  });
}

