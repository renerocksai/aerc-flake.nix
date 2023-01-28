{

  description = "Dev shell for aerc, with paths set up for me";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/release-22.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ...} @inputs : 

    # let systems = builtins.attrNames inputs.zig.packages;
  # in
   flake-utils.lib.eachDefaultSystem (system:
      let pkgs = nixpkgs.legacyPackages.${system}; 
      mypython = pkgs.python39.withPackages(p: with p; [p.vobject]);

      in
      rec {

    packages.system.aerc-tools = pkgs.writeShellScriptBin "install" ''
        # TODO: prepare /var/run/renerocksai-aerc 
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
        packages.system.aerc-tools
      ];

      shellHook = ''
        # once we set SHELL to point to the interactive bash, neovim will 
        # launch the correct $SHELL in its :terminal 
        export SHELL=${pkgs.bashInteractive}/bin/bash
        echo "welcome to the aerc shell"
        export PATH=${pkgs.aerc}/share/aerc/filters:$PATH

        ${packages.system.aerc-tools}/bin/install
        export AERC_TOOLS_BIN=~/.aerc-tools;
      '';
    };
    }

  );

}

