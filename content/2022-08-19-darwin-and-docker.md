+++
title = "nix + darwin + docker"
date = 2022-08-19
[taxonomies]
tags = ["nix","docker","nix-darwin","launchd"]
+++

Docker is a pretty industry prolific tool that gives users the ability to 
be repeatable across environments pretty easily. It's highly ergonomic once setup
and easy to rationalise with what and how it's doing things once you've skimmed the 
basic settings, ran a `hello-world` and dipped your toes in proverbial pools.

![docker](/blog/images/docker.png)

Recently docker made a shift in the ability to use docker desktop for free when it comes to
organisations - this freemium style model is... great! Yep - I'm not going to suggest docker
should continue propping up large businesses with free work produced by awesome people,
it deserves to be a paid product for the polish applied in both docker desktop and 
dockerhub. While I'd still be militantly against utilising a GUI for docker as `compose` really gives
you the tools to manage more complex situations well, it is what it is.

I wanted to use docker on my work machines in a way that lets me both be repeatable and 
repoducable in the output. You _could_ write a shell script that wraps the install of
the docker client, creates a qemu guest, passes the required sock between guest and host then 
you'd be off to the races. But this is both a serious rabbit-hole as well as not 
repoducable by nature.

Enter nix - on nixOS we've got `virtualisation.docker.enable` which is mint! Don't make 
me think about how it's working under the hood and give the ability to use docker, like... pronto.
On darwin however the option for virtualisation doesn't exist. Not only this but we're not on
a linux kernel leading to some extra sauce being required to get everything going.

[Colima](https://github.com/abiosoft/colima) is an awesome project that seeks to wrap the complexity of creating a suitable VM
and gives us a default of "hey - just run the dockers", it's available in a few different places
but best of all: in `nixpkgs` meaning we can either pin or be certain of current version across
any number of builds when using flakes.

To ensure we can just use docker at any point I needed to use `launchd` units to manage the spin up
of colima. There is some hackiness about the way that the launchd unit is defined, but seems like it
catches the obvious edge-cases I encountered; I wrote a simple extension to options for darwin 
(though testing if host system is darwin is an assertion I should include on this) and the end-result 
came out as below:

```nix
{ config, pkgs, lib, ... }:
let
  cfg = config.virtualisation.docker-darwin;
  requiredPackages = with pkgs; [ colima docker ];
in with lib; {
  options = {
    virtualisation.docker-darwin = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = mdDoc ''
          This option enables docker on darwin, a daemon that manages
          linux containers. Users can interact with
          the daemon (e.g. to start or stop containers) using the
          {command}`docker` command line tool.
        '';
      };
      logFile = mkOption {
        type = types.nullOr types.path;
        default = "/tmp/docker-darwin.log";
        example = "/var/log/docker-darwin.log";
        description = ''
          The logfile to use for the docker service.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = requiredPackages;
    launchd.user.agents.docker = {

      path = requiredPackages ++ [ config.environment.systemPath ];

      # Script logic is:
      # check if docker ps gives a zero exit code, if not use `colima start`
      # but guard this also from unclean stops by assuming in another non
      # zero exit that a qemu host exists/is running but host side is borked
      # and pkill the pid if so.

      # Then check colima status, if default (normal colima namespace with start)
      # has a non-zero exit (i.e not running) start it.
      script = ''
        ${pkgs.docker}/bin/docker ps -q || ${pkgs.colima}/bin/colima start || pkill -F ~/.lima/colima/qemu.pid 
        ${pkgs.colima}/bin/colima status -p default || ${pkgs.colima}/bin/colima start default 
      '';

      serviceConfig = {
        Label = "local.docker";
        AbandonProcessGroup = true;
        RunAtLoad = true;
        ExitTimeOut = 0;
        StandardOutPath = cfg.logFile;
        StandardErrorPath = cfg.logFile;
      };
    };
  };
}
```

The only real rough edge I came across was that launchd kills subprocesses once the parent process exits.
Now this might just be not spending enough time reading all the options for launchd but the documentation
of launchd _REALLY_ sucks. The solve for this issue was to add `AbandonProcessGroup` to the 
serviceConfig and launchd stopped killing and reloading docker until infinity.

When [Tweag recently posted the roadmap for nix](https://www.tweag.io/blog/2022-08-04-tweag-and-nix-future/)
they mentioned ubiquity between linux & darwin these kind of rough edges (docker requiring custom written
options) are the kind of things that could really help in the adoption of nix, I'm keen to see what
they come out with!

Yep - I should/could probably create a pull request for the option to be upstream'd into nix-darwin but
the imposter syndrome is real and my implementation of the service could probably be polished a bit.