# Cloud Agent base image for sycamore-hq/berea.
# Pins match specs/003-harness-and-hygiene/plan.md:
#   ocaml 5.5.x (5.5.0 today), dune 3.24.2, melange 7.0.1-55, ocamlformat 0.29.0
# Do not COPY the repo — Cursor checks out the requested revision itself.
#
# ocaml/opam minor tags resolve to the latest patch; the switch is named 5.5
# (no patch). The grep after opam install asserts the compiler is 5.5.x.
# The image repo is the local clone at /home/opam/opam-repository; pin a
# commit before opam update or the package set floats with the weekly rebuild.

FROM ocaml/opam:ubuntu-24.04-ocaml-5.5

ENV DEBIAN_FRONTEND=noninteractive \
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
 && { id -u ubuntu >/dev/null 2>&1 || useradd -m -s /bin/bash ubuntu; } \
 && echo "ubuntu ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/ubuntu \
 && chmod 0440 /etc/sudoers.d/ubuntu \
 && curl -fsSL https://bun.sh/install | BUN_INSTALL=/usr/local bash -s "bun-v1.4.2"

USER opam
WORKDIR /home/opam

# Non-login shells (install / terminals) need the switch on PATH.
# Set it before the install RUN so `ocaml -vnum` is the 5.5 switch, not PATH-less.
ENV PATH="/home/opam/.opam/5.5/bin:/usr/local/bin:${PATH}"

# opam-repository@b99de613 (2026-09-06) resolves the four house pins.
# OPAMYES / OPAMCONFIRMLEVEL stay on this RUN; they must not persist as ENV.
RUN git -C /home/opam/opam-repository fetch --depth 1 origin b99de6133afc2d00ac41252541e04606932e62f7 \
 && git -C /home/opam/opam-repository reset -q --hard FETCH_HEAD \
 && OPAMYES=1 OPAMCONFIRMLEVEL=unsafe-yes opam update \
 && OPAMYES=1 OPAMCONFIRMLEVEL=unsafe-yes opam install -y dune.3.24.2 ocamlformat.0.29.0 melange.7.0.1-55 \
 && ocaml -vnum | grep -Eq '^5\.5\.[0-9]+$'
