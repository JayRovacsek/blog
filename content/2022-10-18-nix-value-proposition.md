+++
title = "nix value proposition"
date = 2022-10-18
[taxonomies]
tags = ["nix","vmdr","daily driver","portability"]
+++

Part of my professional role is considering risk associated with systems, the mitigations, cost, benefit and implications
of addressing a risk versus not. The call in the end is not mine to make and a stakeholder has the final call on what the best path
will be; this is great as the custodian of the resource is well informed in making the best decision for what they need to do.

As with most professionals; I commonly find myself asking but is my input sound, suitable etc - after all, we're just beings 
trying to form a semblance of structure out of the chaos of the universe.

Today I had a few funny conversations that led to a strong urge to just sit down, type and hope some sense would come out of it.
One topic that has been surfaced twice in the last week or so for myself is: what is the value proposition of nix? While this is
not verbatim how it was put, it's the essence of what was asked.

Before I get into the meat of this post, I want to cover off the idea of bandwagoning: I can buy into an idea pretty hard and can point to
two technical ideas recently that this also correlated with a rise in attention for the topic; 
  * Rust
  * nix

Fuck yeah both have been bandwagon topics - they rose from relative obscurity to a revered prominence by a small/medium group of almost
fanatical followers. The meme'y-ness of this is undeniable; [RIIR](https://github.com/ansuz/RIIR) and _I run nixos btw..._ (sorry Arch fans - nix is here to eat your dinner)

{{ resize_image(path="../static/images/arch-vs-nix.webp", width=500 height=500 op="fit") }}

The merit of both of these ideas however is sound, Rust brings to the table a safer way to write mission critical code, while nix
brings to the table deterministic, reproducible builds in both an OS and software sense. Both are total victims to a few shared flaws:
  * ease of use
  * initial knowledge investment / learning curve

This post is not to solve those things - stuff that; RTFM, build a nix package, hack some Rust or don't bother trying to suggest why the idea is bad.
I'm not trying to say all experiences are invalid beyond those in these technical niches; but you can't be taken super seriously saying something along the
lines of "(Rust|nix) is (some variation of negative)" if you haven't invested some time into the idea to come to that conclusion.

Now; I'd like to propose why as a general power-user I believe nix to be some awesome tech; to be significantly groundbreaking in removing a whole class
of problems with package/system management. We're full nix-memelords from here and not going to talk Rust anymore.

# Reproducibility
There are mountains of literature of why reproducible builds matter, there is a need to make clear distinction that reproducibility is
NOT repeatability but a superset of repeatability: docker/build scripts/CICD are neat but very rarely absolutely reproducible.

A great source of information on why reproducibility matter is [Reproducable Builds](https://reproducible-builds.org/). This facet of 
software security is a problem that a large portion of the software development world is not yet mature enough to tackle. There certainly
is a large number of exceptions to this statement, but the truth of what communities are focused on solving is not the problems posed by
reproducibility. They might be focused on delivering a product, expanding a software or some other primary goal and this is a shame for the 
security of end-users; not all software needs this level of scrutiny, but just as privacy is eroded by a "I have nothing to hide" mentality,
so is the normalisation of ensuring software deployments are reproducible.

# An Ability to Audit
An implication of reproducible builds is that a consumer can validate that the output is consistent with a release candidate; irrespective of 
if a second, day or year pass I can validate that the version of a software you are offering is the same as what your source code builds into.

The fallacy of many eyes over open-source software making for more security does come in here; without assessing all of the source code leading up
to the output we cannot have confidence. But the implications of an ability to govern the inputs to ensure a reproducable output are worth their weight
in gold. I want to avoid too many examples in this post; but the below should encapsulate enough of why a generic docker build is not enough unless
explicit on it's inputs:

```dockerfile
FROM node:lts-alpine3.16

RUN apk add --no-cache python3 make g++
```

Cool - the above would give us a base environment that has nodejs in LTS flavour; python3, make and g++. 

There's at-least four issues with this - and if you picked the `apk add` items as problematic before now - ten points to your house.
The fourth issue in above is in the base image used - at time of writing that would be a nodejs v16 install on alpine.

In a [week's time](https://github.com/nodejs/release#release-schedule) this is likely to jump to nodejs v18. Sure you're probably noting that you could pin the nodejs version also via `node:16-alpine3.16` but all of these things are just another footgun to experience when a situation exists where a package just doesn't build under a version of node.

This is not even starting on the fact that the versions on python3, make and g++ are likely to change over time with an inability for us to pin those short of wget'ing their release candidates explicitly and manually managing them as an install in our dockerfile. This is pain.

Consider instead a nix-shell environment that will always resolve to a consistent version of the required packages:

```nix
{ nxipkgs ? import (fetchTarball {
  name = "22.05";
  url = "https://github.com/NixOS/nixpkgs/archive/refs/tags/22.05.tar.gz";
  sha256 = "0d643wp3l77hv2pmg2fi7vyxn4rwy0iyr8djcw1h5x72315ck9ik";
}) { }}:
let
  buildInputs = with nixpkgs; [ nodejs-16_x libgcc python3Minimal gnumake ];
  name = "some-dev-env";
  shellHook = "";
in stable.mkShell {
  inherit buildInputs name shellHook;
}
```

The above is likely a foreign construct for someone new to nix (and hence the killer of nix is usability not functionality), but achieves the following:
  * nixpkgs is available; explicitly pinned to the 22.05 release with a hash validation of the received payload
  * nodejs, g++, python3 and make are fixed on versions that _cannot_ change unless we change the source.

There's some hidden gems in the above also however; this is a shell configuration: it is _ephemeral_ in terms of the applications existing in your shell.
There's no need to consider managing the version of python here and in another project that needs 3.10 or 3.6 when we are using 
[3.9.13](https://search.nixos.org/packages?channel=22.05&show=python3Minimal&from=0&size=50&sort=relevance&type=packages&query=python3Min) very explicitly.
We load these files into our path, use them for our requirements and then do not have them pollute our device beyond their requirement. Depending on how we've got
garbage collection configured on a system they might exist if you know where to look for them up to an indefinite future; for example:
```sh
/nix/store/shpy4sb7k20x9ilry8r6y8cr75b1q2x9-nodejs-16.14.0 
```

# VMDR
I'm a security dude. I care alot about the composition of software and systems as covered somewhat in the first paragraph of this post.
Because of how a nix package requires other nix packages to build we can know the all requirements to build our package or system meaning
those vulnerability management detection and response systems are something we can be extremely close to replicating without paying a kidney a 
year to achieve.

Consider the before mentioned version of nodejs on my system: `16.14.0` - what went into this build? Using [nix-visualize](https://github.com/craigmbooth/nix-visualize) we can generate a neat image depicting a dependency graph:

{{ resize_image(path="../static/images/nodejs-16.14.0-deps.png", width=14400 height=7200 op="fit") }}

The output of the above is smaller than I'd like but if the image is opened in a new tab it might be more consumable for a viewer. The tldr of it is that we get an explicit set of dependencies that are required for the package meaning we can pull data related to each of these packages from NIST to understand what/if we have vulnerability exposure _ahead_ of time if we are so inclined.

The awesome folk creating [vulnix](https://github.com/flyingcircusio/vulnix) have enabled us to point at a derivation (a build in nix terms), gather all data related from [NIST](https://nvd.nist.gov/vuln/) and get an exposure list going.

This is not just for packages - as a system's configuration is a derivation that includes
dependencies and those dependencies likely dependencies; we can understand if our current system is weak to flaws, if our build/runtime dependencies are weak to flaws 
and extend this out to understand if we update a system, is it still vulnerable to these issues.

{{ resize_image(path="../static/images/seed_207087_00006.png", width=500 height=500 op="fit") }}
A pointless Stable Diffusion generated muppet image.

# I'm Getting Tired
This post won't wrap up in a nice summary of all the reasons nix is cool AF - but should showcase at-least two reasons of why
the investment in learning nix is a solid one if you:
  * hate encountering "works on my machine (tm)"
  * want to develop an app without thought on installing; go, rust, python, racket, zig, java, a mixture or ALL of these at the same time
  * care about your system:
    * being managed by you and not M$/Tim Apple
    * being measurable in terms of vulnerabilities (that are known)
    * being consistent in behavior
    * being portable if you have reason to migrate it at some point or just want to test changes

What I haven't really covered in this is:
  * generations
  * read-only / immutable package installs
  * per-user installs
  * dotfile management so your $PROGRAM acts the same way across multiple systems
  * source-control aware build systems (if it ain't see by source control, it ain't considered by nix)
  * build environment sandboxes to ensure purity of inputs/outputs
  * cross compilation capabilities

These are the reasons the time I've utilised to learn nix is, in my books a great investment - hopefully we see either nix or
something like nix lead the next epoch of software engineering & system management that we pretty desperately need.