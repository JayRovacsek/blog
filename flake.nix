{
  description = "My Blog";

  inputs = {
    devshell = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:numtide/devshell";
    };

    flake-utils = {
      inputs.systems.follows = "systems";
      url = "github:numtide/flake-utils";
    };

    git-hooks = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:cachix/git-hooks.nix";
    };

    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    systems.url = "github:nix-systems/default";
  };

  outputs =
    {
      devshell,
      flake-utils,
      nixpkgs,
      self,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          overlays = [ devshell.overlays.default ];
          inherit system;
        };
      in
      {
        checks = {
          git-hooks = self.inputs.git-hooks.lib.${system}.run {
            src = self;
            hooks = {
              # Builtin hooks
              actionlint.enable = true;

              deadnix = {
                enable = true;
                settings.edit = true;
              };

              nixfmt = {
                enable = true;
                package = pkgs.nixfmt-rfc-style;
                settings.width = 80;
              };

              prettier.enable = true;

              typos = {
                enable = true;
                settings = {
                  binary = false;
                  ignored-words = [ ];
                  locale = "en-au";
                };
              };

              # Custom hooks
              statix-write = {
                enable = true;
                name = "Statix Write";
                entry = "${pkgs.statix}/bin/statix fix";
                language = "system";
                pass_filenames = false;
              };

              trufflehog-verified = {
                enable = pkgs.stdenv.isLinux;
                name = "Trufflehog Search";
                entry = "${pkgs.trufflehog}/bin/trufflehog git file://. --since-commit HEAD --only-verified --fail --no-update";
                language = "system";
                pass_filenames = false;
              };
            };
          };
        };

        devShells.default = pkgs.devshell.mkShell {

          devshell = {
            startup.git-hooks.text = self.checks.${system}.git-hooks.shellHook;

            interactive.shell.text = ''
              ${pkgs.git}/bin/git submodule update --init
              port_used=$(${pkgs.lsof}/bin/lsof -i -P -n | ${pkgs.gnugrep}/bin/grep LISTEN | grep 8080 | ${pkgs.coreutils}/bin/wc -l)
              if [ $port_used -eq 1 ]
              then
                echo "Port 8080 appears to be in use, not starting zola"  
              else
                ${pkgs.coreutils}/bin/rm -rf ./public
                ${pkgs.zola}/bin/zola serve --port 8080
              fi
            '';
          };

          name = "blog shell";

          packages = with pkgs; [
            actionlint
            conform
            deadnix
            git
            git-cliff
            lsof
            nixfmt-rfc-style
            nodePackages.prettier
            statix
            statix
            trufflehog
            typos
            zola
          ];
        };

        formatter = pkgs.nixfmt-rfc-style;

        package.blog = { };
      }
    );
}
