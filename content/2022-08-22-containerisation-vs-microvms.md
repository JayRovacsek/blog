+++
title = "containerisation vs microvms"
date = 2022-08-22
# draft = true
[taxonomies]
tags = ["nix","microvm","tailscale","nixos","docker"]
+++

**_Please note that this page is a work in progress, of which I may be unlikely to return to.
If it is incorrect or differs from my current thoughts; that's because it's sat on my drive
since the original draft date uncommitted - I don't really intend to complete it, but do
intend to commit it in order to track it over time._**

Abstracting systems to run in a large number of environments is great, you start
to breakdown the "works on my machine" issue and make the process of running a workload
agnostic (for the most part) of the host.

Docker is a prime example of this, while it still requires a linux kernel under the hood,
it's relatively easy to have this para-virtualised via WSL on windows thanks to [hyper-v
running as the hypervisor for windows](https://www.thomasmaurer.ch/2019/06/install-wsl-2-on-windows-10/)
meaning what's really the cost of a small linux kernel running along side windows?

But as a "security" person, I have some bones to pick with docker.

But before I start to whine about stuff that is really both the nth degree of security or optimisation
I acknowledge that a well written and designed docker solution addresses most of the issues in this
post.

<h1>Optimisation of disk usage</h1>

But ain't docker got those layers? The reuse of common layers will save us
right? Yes and no, layers are great and save transfer and disk space utilisation but they depend on
the layers to be written in a way that is consistent and (hopefully) relatively optimised.

The above will be true for most rather well trodden images but can quickly fall apart once the
image we're looking at using is not as mature or still a work in progress. While it would seem that
a few MB here or there wouldn't matter too much in the grand scheme of things, it can really add up
once you're talking millions of downloads (yep docker caching is a thing also, but we're still sending
bits over the wire that have a sole use in a single layer)

For example; we can compare python images tagged:

- 3.10-alpine
- 3.10-slim-buster

It's expected that the layers governing either debian or alpine will be different, and we'd expect if the python
binary is coming from the respective `deb/apt/apk` sources that it'd be different based on how the packaging
formats work. But the maintainers of these images are actually awesome and are pulling a consistent source
from [python.org](https://www.python.org) as shown in these lines:

[From Alpine](https://github.com/docker-library/python/blob/7b9d62e229bda6312b9f91b37ab83e33b4e34542/3.10/alpine3.16/Dockerfile#L59):

```sh
wget -O python.tar.xz "https://www.python.org/ftp/python/${PYTHON_VERSION%%[a-z]*}/Python-$PYTHON_VERSION.tar.xz";
```

[From Debian](https://github.com/docker-library/python/blob/7b9d62e229bda6312b9f91b37ab83e33b4e34542/3.10/slim-buster/Dockerfile#L56):

```sh
wget -O python.tar.xz "https://www.python.org/ftp/python/${PYTHON_VERSION%%[a-z]*}/Python-$PYTHON_VERSION.tar.xz";
```

Yep - we can see the step also includes GPG validation of the download and some other nice stuff, but if we are putting python in the
same location and pulling from the source it seems sane that we could re-use the layer across both images. Maybe there's great
reason to do this all in one step and remove reusability of the layer, but we could just install dependencies outside of python
and then install python in a consistent manner making the layer reusable.

[images]

Utilisation of root/docker service user as container user; generally when users are first introduced to
docker they're under a bit of a false understanding that the idea of containerisation means security, and
generally it is a security uplift over running natively on a host. But seeing people opt into either installing
docker in a rootless mode or ensuring that containers are ran with a `--user` flag that is suitable
is less common. This conceptually shouldn't matter too much when you're using the `--security-opt=no-new-privileges:true` option
for containers also, but this is just as uncommon as the afore mentioned issues.

```sh
➜ whoami
root
➜ id
uid=0(root) gid=0(root) groups=0(root)
```

Generally people are pretty aware of the above; but with time pressures, the work to
shift from a quick install to get everything running to applying more
secure-by-default settings can easily become a never job.

**_As described at the top of the document, this is incomplete, consider
the below to be a scratchpad of ideas_**

- users on an image
- using root
- readonly fs (https://docs.datadoghq.com/security_platform/default_rules/cis-docker-1.2.0-5.12/)
- latest as default tag

Microvms:

- SDN for access
- readonly fs
- reused host files
- fill kernel not reuse host kernel
