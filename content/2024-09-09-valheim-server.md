+++
title = "valheim server"
date = 2024-09-09
[taxonomies]
tags = ["technology","nix","nixos","games","iac","docker"]
+++

# background

Recently(ish) Valheim's Ashland's patch was released, my wife and I
had really enjoyed all of our playthroughs of Valheim to date (so
far one per major release since roughly Hearth & Home)

Historically I'd leveraged [docker via portainer](https://www.portainer.io/)
which had made the process pretty easy; this time I'd follow the
same path, but still seek to minimise what I can of the nice and
shiny elements that portainer brings, given I'd finally got my
home server down to <i>zero docker</i> running on it in favour of
native options.

ValheimPlus or mods were a need to have, given we'd struggle for
time to play besides 8pm+ which we both accept as time that'll
be consumed from a good night sleep. While I archived my [dotfiles](https://github.com/jayrovacsek/dotfiles)
repository, it was able to save me from rebuilding much of an
understanding of the require run configuration from a container
perspective.

{{ resize_image(path="../static/images/teleport-ore.jpg", width=1200 height=1159 op="fit") }}

# server build

To avoid utilising a full install of portainer, <i>and docker
in favour of podman</i> I utilised the various `virtualisation`
options available in nixos. The translation between a compose
file and the expected module structure was relatively easy
and ended up looking akin to this:

```nix
{ config, ... }:
{
  networking.firewall.allowedUDPPorts = [
    2456
    2457
  ];

  users = {
    groups.valheim = {
      gid = 10105;
      members = [ "valheim" ];
    };
    users.valheim = {
      group = "valheim";
      isSystemUser = true;
      uid = 10105;
    };
  };

  virtualisation = {
    podman = {
      autoPrune = {
        dates = "daily";
        enable = true;
      };
      dockerCompat = true;
      enable = true;
    };

    oci-containers = {
      backend = "podman";
      containers.valheim = {
        environment = {
          SERVER_NAME = "REDACTED";
          SERVER_PASS = "REDACTED";
          SERVER_PUBLIC = "false";
          RESTART_CRON = "";
          TZ = config.time.timeZone;
          BACKUPS_MAX_AGE = "5";
          BACKUPS_IF_IDLE = "false";
          VALHEIM_PLUS = "true";
          PUID = "${builtins.toString config.users.users.valheim.uid}";
          PGID = "${builtins.toString config.users.groups.valheim.gid}";

          VPCFG_ValheimPlus_enabled = "true";
          VPCFG_ValheimPlus_serverBrowserAdvertisement = "false";

          # More VPCFG_ options, but excluded to avoid a huge example
        };
        extraOptions = [
          "--cap-add=sys_nice"
        ];
        image = "ghcr.io/lloesche/valheim-server";
        ports = [
          "2456-2457:2456-2457/udp"
        ];
        volumes = [
          "/srv/games/servers/2024-valheim-server/config:/config"
          "/srv/games/servers/2024-valheim-server/data:/opt/valheim"
        ];
      };
    };
  };
}
```

There's a fair bit I can do still with this config, but in essence
it provides the same expectations as portainer without a need for
the full portainer experience. The nix options will default to it
auto-running and we're golden from there.

## server opportunities for uplift

### common service codification

Moving ports and other magic values here would ensure the module can be simplified further

### systemd tmpfile rules

The creation of the required directories was a manual task,
the codification of the folders could be fond with correct
user ownership via [systemd.tmpfiles.rules](https://search.nixos.org/options?channel=unstable&show=systemd.tmpfiles.rules&from=0&size=50&sort=relevance&type=packages&query=systemd.tmpfiles.rules)

### backups

Inclusion of the game folders into an automated backup configuration
would ensure minimal risk of lost data into the future (though
the only time I've been bitten by this was palworld)

## server gotcha moments

Initially the build failed as environment variables within
the container module in nixos expect to be of key: value
structure and only string: string typed. This really sucks
as I'm really not confident in the end values being correctly
interpreted.

What sucks just as much is that docker compose or run commands
can commonly take a string or literal interchangeably, so
the required values of true/false or 1 vs 100 are somewhat of
an enigma until I get a chance to read the documentation on it...

# setting up a client

The [main repository](https://github.com/valheimPlus/ValheimPlus)
of valheim plus is not under active development. A fork by
[Grantapher](https://github.com/Grantapher) seems to be
[active](https://github.com/Grantapher/ValheimPlus), so I followed
instructions on there.

In short, the use of `r2modman` was the direction I took; it was
already packaged in nix so was easy to test initially:

```sh
nix-shell -p r2modman
r2modman
```

Then commit to the route with an addition of the package to my
configuration.

## client issues

I can't remember what or how I'd previously played valheim on;
I have to assume it was linux for sure, but certainly under
x11 is my intuition. As my workstation is currently running on
hyprland and therefore wayland, I was immediately bitten by an
inability to play by default.

It seems a fair few people have hit similar issues to what I
experienced and thankfully one of the <i>last options</i> I
tried resolved my issues.

My client would initially just crash; a lot of threads online
pointed to this being wayland specific: so try force it into
xwayland.

### removing sdl_videodriver & wayland_display

As hyprland suggests the use of setting sdl_videodriver to wayland
the first move was to remove that. It stopped the game crashing
immediately but left me with a white or red screen on load.

Further suggestions were to unset wayland_display which also just
led to a white or red screen. Given neither of these ideas
helped, I tried one of the last things that might have helped;
run valheim under wayland

## client issue resolution

A combination of ensuring the ld_preload included libsdl2-2.0.so.0
as well as a [resolution adjustment in launch settings](https://valheimbugs.featureupvote.com/suggestions/174345/read-here-fix-for-black-screen-when-launching-valheim)
seemed to resolve my issues.

## client opportunities for uplift

Adding the ld_preload and launch options to steam, screams at me
as a file within my home directory; it'll totally be this so
addition of the file via home managers `home.file` option
would be optimal. To set ld_preload I utilised a nice footgun
that will likely bite me over time when garbage collect runs:

```sh
nix repl
:lf .
# Build SDL2
:b nixosConfigurations.alakazam.pkgs.SDL2
# Look at outpath for location of files (emitted from previous step to be fair)
nixosConfigurations.alakazam.pkgs.SDL2.outPath
```

Given the launch options r2modman provides, follow the chain of
shell script to this file: `/home/$USER/.config/r2modmanPlus-local/Valheim/profiles/$R2_PRODILE_NAME/start_game_bepinex.sh`
then add a line before anything launches:

```
export LD_PRELOAD="${nixosConfigurations.alakazam.pkgs.SDL2.outPath}/lib/libSDL2-2.0.so.0"
```

Replacing the pkg source where required of course. As SDL2 might
not be in a required root on my system; it's likely that scheduled
garbage collect will delete it: hence the codification of the
package within a configuration file would ensure this doesn't cause
issue later.

{{ resize_image(path="../static/images/troll-mining.jpg", width=609 height=500 op="fit") }}
