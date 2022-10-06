+++
title = "terraform, nix, nixos and terranix"
date = 2022-10-07
[taxonomies]
tags = ["nix","iac","terraform"]
+++

For various reasons I have a need to create cloud services in a simple, declarative and consistent way.
The answer to this is clear depending on which cloud I am looking to use (spoilers; it's AWS for now) and
generally that would be AWS CDK - a neat way to package everything I need (maybe except a single edge-case but
that might just be a PBKAC issue)

Then I got thinking about the deployment of organisations, as is recommended by everyone when it comes to 
putting a clear delineation between development, production and root accounts to begin with and AWS accounts.
I have only skimmed over the surface of setting this up thus far and would love to chase it up sometime over the next week or two but
from a high level it looks like AWS organisations are going to be easy to setup with terraform.

Looking at the requirements for state, we really want to store tfstate in a S3 bucket; which feels like a fair bit of a 
chicken and egg situation: 
* I want to deploy terraform to manage AWS infrastructure
* Terraform requires state - S3 or local (or others, but lets ignore that)
* S3 would require an S3 bucket - of which this should not live in a root account
* Non-root account requires organisation provisioned

Yeah...

Anyways; I suppose a local state that's migrated to S3 later could work; alternatively a hand-rolled development/deployer
organisation that is later captured as state to enable the whole configuration to be represented.

Moving away from just the deployment of org structures; I'm in love with the idea of defining a nixOS configuration,
building an AMI then deploying to variable size instances with scheduled up/down rules to replace the by-hand
CSGO server I'm currently running for work to be a wind-down activity on a Friday.

This'll need to be proved out, but coupling a flake with the [nixos generators](https://github.com/nix-community/nixos-generators)
repository
it seems dead easy to do so!

Maybe there'll be a post in a few weeks from me lamenting the journey, or celebrating it's success! 