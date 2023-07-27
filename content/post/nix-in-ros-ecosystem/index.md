---
title: How does Nix fit into the ROS 2 ecosystem?
date: 2023-07-24T21:21:22+10:00
tags:
  - Nix
  - ROS
---

Nix is a featureful package manager and build tool. Where exactly can it
fit in to the existing ROS 2 ecosystem? Let's explore.

## The standard ROS 2 build responsibility chain

Imagine a regular ROS 2 environment, on a regular Linux distribution.

Software (both regular and ROS 2) is installed via the system package manager,
typically from the official distribution or ROS software repositories. The
collection of available software is heavily tied to the distribution. If your
distro goes EOL, you're SOL - no more updates for you.

[colcon](https://colcon.readthedocs.io) is the primary tool used to
manage local ROS workspace installations, and build packages. It is a
["build tool" that acts as an abstraction layer over various "build systems"](https://design.ros2.org/articles/build_tool.html)
such as [setuptools](https://setuptools.pypa.io) or [CMake](https://cmake.org),
and configures such build systems to find ROS package dependencies before
starting them.

These technologies can be laid out in a "chain of responsibilities" diagram, like so.

```goat
         .------------.
        |              |          > Provides OS services
        | ROS-capable  |          > Provides package manager
        | Linux distro |          > Provides non-ROS software
        |              |
         '-----v------'
         .------------.
        |              |          > Provides, and lets build systems find,
        |  ROS distro  |            official ROS packages
        |   packages   |
        |              |
         '-----v------'
         .------------.
        |              |          > Lets build systems find workspace packages
        |    colcon    |          > Executes build systems
        |              |          > CLI entrypoint
         '-v--------v-'
 .------------.   .------------.
|              | |              | > Adds ROS features to standard build systems
| ament_python | | ament_cmake  |
|              | |              |
 '-----+------'   '-----+------'
 .-----+------.   .-----+------.
|              | |              | > Builds and packages ROS packages
|  setuptools  | |    CMake     |
|              | |              |
 '-----v------'   '-----v------'
 .------------.   .------------.
|              | |              |
| Python code  | |  C++ code    |
|              | |              |
 '------------'   '------------'
```

## The ROS 2 build responsibility chain with Nix

Nix is quite well suited to the roles of both the system package manager and
colcon.

Just like the system package manager, Nix provides a large collection of
independent [regular](https://github.com/NixOS/nixpkgs) and [ROS](https://github.com/lopsided98/nix-ros-overlay)
packages. Just like colcon, it is a build tool designed to configure build
environments and run build systems inside them.

Using Nix, our responsibility chain now looks like this.

```goat
         .------------.
        |              |          > Provides OS services
        |  Any Linux   |
        |    distro    |
        |              |
         '-----v------'
         .------------.
        |              |          > Provides non-ROS software
        |     Nix      |          > Provides, and lets build systems find,
        |              |            official ROS packages
         '-----v------'
         .------------.
        |              |          > Lets build systems find workspace packages
        | Nix or colcon|          > Executes build systems
        |              |          > CLI entrypoint
         '-v--------v-'
 .------------.   .------------.
|              | |              | > Adds ROS features to standard build systems
| ament_python | | ament_cmake  |
|              | |              |
 '-----+------'   '-----+------'
 .-----+------.   .-----+------.
|              | |              | > Builds and packages ROS packages
|  setuptools  | |    CMake     |
|              | |              |
 '-----v------'   '-----v------'
 .------------.   .------------.
|              | |              |
| Python code  | |  C++ code    |
|              | |              |
 '------------'   '------------'
```

## Nix or colcon?

Nix is almost always an upgrade over the system package manager, but at the
package development level, the choice of build tool is not often so easy.
Both Nix and colcon have their own benefits and drawbacks in various situations.

### Reasons to use Nix

- **Nix allows you to start a shell in any package's build environment**,
  letting you work with the lowest-level build system directly. This is
  especially useful when working with IDEs, as no special ROS-specific setup is
  required.
- **Nix packages can be easily deployed to any device.** Using [`nix-copy-closure`](https://nixos.org/manual/nix/stable/command-ref/nix-copy-closure.html)
  or [substituters](https://nixos.org/manual/nix/stable/glossary.html?highlight=substitut#gloss-substituter),
  a package can be copied to another device along with all its runtime dependencies.
  This means that ROS packages can be built in advance on powerful hardware to
  be later sent to a low-power embeded device.
- **Nix builds never fail on account of missing dependencies.** Unlike colcon,
  which relies on manual invokation of external tools such as [rosdep](https://docs.ros.org/en/rolling/Tutorials/Intermediate/Rosdep.html)
  to install dependencies, Nix sets up the entire build environment for each
  package itself, and prevents undeclared system software from being seen by the
  build system.
- **Nix has a rich tooling ecosystem.** Nix packages can be easily integrated
  into NixOS systems, and CI/CD is well supported by [Hydra](nixos.org/hydra).

### Reasons to use colcon

- **colcon is good at working with multiple packages at once.** It can generate
  setup scripts that allow all the packages being developed to see each other.
  Nix can do this too, but it is not designed with this use case in mind.
  Acheiving this with incremental compilation in Nix is difficult.

- **colcon is faster for rapid iteration.** The build tool has features such as
  [`--symlink-install`](https://colcon.readthedocs.io/en/released/reference/verb/build.html?highlight=symlink-install)
  and built-in support for incremental compilation to allow packages to be
  modified swiftly. Nix cannot do either of these things easily.

- **colcon can build any ROS package with no extra configuration**, as long as
  the dependencies are available. ROS packages built with Nix must first have
  derivations written, which makes it harder to get started quickly.

### Which build tool should I use?

I recommend using a combination of Nix and colcon. Nix, for single-package
development (due to the ease of IDE integration), deployment, and CI/CD; and
colcon, for multi-package development.