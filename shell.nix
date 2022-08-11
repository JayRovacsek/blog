{ pkgs ? import <nixpkgs> { } }:
pkgs.mkShell {
  name = "blog shell";
  buildInputs = with pkgs; [ git zola nixfmt statix ];
  shellHook = ''
    git submodule update --init
    port_used=$(lsof -i -P -n | grep LISTEN | grep 8081 | wc -l)
    if [ $port_used -eq 1 ]
    then
      echo "Port 8080 appears to be in use, not starting zola"  
    else
      zola serve --port 8080
    fi
  '';
}
