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
    mypython = pkgs.python39.withPackages(p: with p; [p.vobject]);

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
        ln -s ${mypython}/bin/python $AERC_TOOLS_BIN/python
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
          mypython
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

    defaultPackage = packages.aerc-run;

    # we want a shell, where all relevant executables, filters etc 
    # are on the path, so we don't need explicit, package-specific 
    # nix-store paths in our config
    devShells.default = pkgs.mkShell {
      nativeBuildInputs = with pkgs; [
          bat
          less
          aerc
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
          mypython
          packages.aerc-tools-install
          aerc # overlay added all other runtime deps
          bashInteractive
      ];

      shellHook = ''
        export SHELL=${pkgs.bashInteractive}/bin/bash
        echo "welcome to the aerc shell"
        export PATH=${pkgs.aerc}/share/aerc/filters:$PATH

        ${packages.aerc-tools-install}/bin/aerc-tools-install
        export AERC_TOOLS_BIN=~/.aerc-tools;
      '';
    };
  });
}

