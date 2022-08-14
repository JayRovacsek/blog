+++
title = "nix + MVP SOEs"
date = 2022-08-15
[taxonomies]
tags = ["nix","soe","nix-darwin"]
+++

A question came up recently around if nix could be leveraged to simplify an onboarding and
asset management. There isn't a simple answer for this but we figured we'd consider evaluating
the option on darwin hosts as an option rather than expecting end-users to install the base 
tools & apply configuration on a system in the same way policy expects it.

Because I've already nix'd a few darwin machines I could re-use the configuration for the most 
part which was nice. After having created a repo and copying the relevant files across I 
started with solving the problem of applying explicit requirements for a number of hosts 
that users couldn't just override.

We'll ignore the fact that if a user is an administrator that they can override whatever they'd like
but the risk of insider threat isn't what we're trying to address here.

As all system configurations will be an output of `darwinConfigurations` when it comes to the flake,
we can dynamically assess files within a `hosts` folder from the `flake.nix` file so that:
* users have no need to define their host in the flake, it's done auto-magically once a valid host config exists
* user changes to the repo can be applied against host configs or modules and the base opinions required by policy are for the most part immutable as code

With the above considered, we can write some basic variable declarations before the main block of the flake 
that handles the logic:

```nix
{
  description = "Darwin configurations";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-22.05";

    firefox-darwin = {
      url = "github:bandithedoge/nixpkgs-firefox-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    darwin = {
      url = "github:lnl7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:rycee/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agenix-darwin = {
      url = "github:cmhamill/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, darwin, firefox-darwin, agenix
    , agenix-darwin, ... }:
    let
      fileNames = path: builtins.attrNames (builtins.readDir path);

      localOverlays = import ./overlays;
      darwinOverlays =
        [ firefox-darwin.overlay agenix-darwin.overlay localOverlays ];

      standardiseNix = {
        environment.etc."nix/inputs/nixpkgs".source = nixpkgs.outPath;
        nix.nixPath = [ "nixpkgs=/etc/nix/inputs/nixpkgs" ];
      };

      flake = { config._module.args.flake = self; };

      aarch64-darwin = import nixpkgs {
        system = "aarch64-darwin";
        overlays = darwinOverlays;
        config = { allowUnfree = true; };
        extraModules = [ ];
      };

      base-modules =
        [ flake standardiseNix agenix-darwin.nixosModules.age ./modules/base ];

      hostNames = (fileNames ./hosts);

      hostConfigurations = builtins.filter (hostName:
        builtins.any (filename: filename == "default.nix")
        (fileNames ./hosts/${hostName})) hostNames;

      darwinConfigurations = builtins.foldl' (x: y: x // y) { } (builtins.map
        (hostName: {
          "${hostName}" = darwin.lib.darwinSystem {
            inherit (aarch64-darwin) system;
            pkgs = aarch64-darwin;
            modules = [ ./hosts/${hostName} ] ++ base-modules;
          };
        }) hostConfigurations);
    in {
      inherit darwinConfigurations;
    };
}
```

The above is a bit of a mess but in essence will check children of the `hosts` folder 
for suitable `default.nix` files and then generate a system configuration from it; 
applying our base module set.
(Yep - totally aware that the logic is a little flawed as it assumes children of the hosts folder are folders
only, but that'll be a quick change once I get a moment) 

With the above said and done, we can add to the `modules/base` definition and all system configurations 
defined will inherit from the base-modules. I'll need to dig into if `lib.mkForce` allows the override of these settings
but anticipate the behavior is an error due to the same value being applied twice if a user were to 
include a duplicate option to one in the base modules.

The above is still a total WIP, but was promising to get a fair bit done in such a short period. The idea of a nix SOE
is very much somewhat a hobbled version when you're using darwin as a base, but it'll be easy enough to shift the
configuration into a Linux iteration also which enables us to use the awesome work of [nixos-generators](https://github.com/nix-community/nixos-generators)
meaning we'll not only have the option to define a Linux SOE that works on metal but generation of a disk 
image will be easy to enable further POC.