+++
title = "forbidden router"
date = 2024-08-18
[taxonomies]
tags = ["technology","pfsense","nix","nixos","router","development","iac"]
+++

Searching for a term that best describes what I'm trying to represent returns "obsession",
which is not untrue, but I believe it's not quite the term I'm looking for.

For a while now, I have been **obsessed** with configuration as code & general reproducibility of a system; my
systems all adhere to this idea now, but I'm still missing this on a few key components of my
technological life:

- pfsense
- switch
- phone

The latter two are not the brain-bug I'm currently harbouring, the idea the network gateways, dhcp server and dns forwarder
for badly behaving traffic could be defined as pure code/configuration is super exciting. The only killer for this
idea is time.

Now reaching [9 months old at time of writing](https://github.com/JayRovacsek/pf-to-nixos/commit/985f66f47a93370024e6634a53b7724112ae2e94),
I should probably be celebrating the birth of this idea into **really stale territory**. Conceptually the mapping of a pfsense or
opnsense xml configuration to suitable json / nix code that can be utilised to enable a migration path is nothing more than
time investment; it isn't complex and all concepts should map well.

I've recently started thinking on this space again, given the rapid maturity uplift I enjoyed when updating a
Debian instance running openvpn; only to find everything broken and my distaste for `apt/dpkg` and `ufw`
to still be a thing (to be fair, it's likely the frustration with this is just a symptom of not knowing the tools
intimately). I intend to jot my thoughts down more deeply about that journey soon, but in essence re-implementing the
openvpn server being as simple as [this](https://github.com/JayRovacsek/nix-config/commit/119e24de7b00ae3a2654dd5e092c448a9db45e0c#diff-591c1919a2576b637902831b0c560309c4815fbd34deb2acfe8798f97301d0db)
just reminded me that I should invest some time into going on this journey.

Building this configuration as a microvm would be an achievemnent, enabling the removal of physical kit from my
office at the cost of complexity in technical space. Level1Techs did a few awesome pieces on the boons
and pitfalls of forbidden routers not too long ago:

{{ youtube(id="r9fWuT5Io5Q") }}

{{ youtube(id="MBY_QNN3owc") }}

{{ youtube(id="x40FlIyhYXU") }}

There's even a reasonably mature space of people utilising nixos to represent their routers within Github,
plus an awesome initiative to [enable routers via a framework](https://github.com/chayleaf/nixos-router)!

Once migrated, data related to the network and configuration could be consumed by various hosts within the `self`
attribute of `specialArgs` enabling configurations that are much more network aware. I've naturally started to head
in this direction via `common` [attribute values](https://github.com/JayRovacsek/nix-config/blob/6392de32ed3764010579c58bda08d0befaaf23b3/common/config.nix)
but could see the future of a core network as pretty resilient to failed upgrades or migrations, that also enables more host
aware configurations to exist.

Past that, overlay networks consuming the core network configuration too would mean a level of deprecation could occur in
firewall and network routing, in favour of the network segments being extremely simple pigeonholes that allow for egress to the world
via a defined gateway, simply to broker overlay connectivity for internal reachability considerations.

There's no conclusion to this brain dump, beyond **wouldn't it be nice**!

{{ resize_image(path="../static/images/field.png", width=500 height=500 op="fit") }}
