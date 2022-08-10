{ pkgs ? import <nixpkgs> { } }:
pkgs.mkShell {
  name = "blog shell";
  buildInputs = with pkgs; [ zola nixfmt statix ];
  shellHook = "";
}