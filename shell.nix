{ pkgs ? import <nixpkgs> { } }:
pkgs.mkShell {
  name = "blog shell";
  buildInputs = with pkgs; [ git zola nixfmt statix ];
  shellHook = ''
    git submodule update --init
    zola serve --port 8080
  '';
}
