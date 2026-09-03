# Cloud Agent base image for sycamore-hq/berea.
# Pins match specs/003-harness-and-hygiene/plan.md:
#   ocaml 5.2.0, dune 3.24.2, melange 7.0.1-52, ocamlformat 0.29.0
# Do not COPY the repo — Cursor checks out the requested revision itself.

FROM ocaml/opam:ubuntu-24.04-ocaml-5.2

ENV DEBIAN_FRONTEND=noninteractive \
    OPAMYES=1 \
    OPAMCONFIRMLEVEL=unsafe-yes \
    OPAMCOLOR=never \
    OPAMROOT=/home/opam/.opam

USER root
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      git \
      sudo \
      unzip \
 && rm -rf /var/lib/apt/lists/* \
 && echo "opam ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/opam \
 && chmod 0440 /etc/sudoers.d/opam \
 && id -u ubuntu >/dev/null 2>&1 || useradd -m -s /bin/bash ubuntu \
 && echo "ubuntu ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/ubuntu \
 && chmod 0440 /etc/sudoers.d/ubuntu \
 && curl -fsSL https://bun.sh/install | BUN_INSTALL=/usr/local bash

USER opam
WORKDIR /home/opam

# The image switch is named 5.2 (compiler 5.2.0).
RUN opam update \
 && opam install -y dune.3.24.2 ocamlformat.0.29.0 melange.7.0.1-52

# Non-login shells (install / terminals) need the switch on PATH.
ENV PATH="/home/opam/.opam/5.2/bin:/usr/local/bin:${PATH}"
