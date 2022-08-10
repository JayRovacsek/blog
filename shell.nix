{ pkgs ? import <nixpkgs> { } }:
pkgs.mkShell {
  name = "blog shell";
  buildInputs = with pkgs; [ git zola nixfmt statix ];
  shellHook = ''
    git pull --recurse-submodules
    zola serve --port 8080
  '';
}