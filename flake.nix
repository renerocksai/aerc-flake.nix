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
        mypython
      ];

      # buildInputs = with pkgs; [
      #   # we need a version of bash capable of being interactive
      #   # as opposed to a bash just used for building this flake 
      #   # in non-interactive mode
      # ];

      shellHook = ''
        # once we set SHELL to point to the interactive bash, neovim will 
        # launch the correct $SHELL in its :terminal 
        export SHELL=${pkgs.bashInteractive}/bin/bash
        echo "welcome to the aerc shell"
        touch /home/rs/touched
      '';
    };
    }

  );

}

