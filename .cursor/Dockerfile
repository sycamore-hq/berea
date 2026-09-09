# Cloud Agent base image for sycamore-hq/berea.
# Pins match specs/003-harness-and-hygiene/plan.md:
#   ocaml 5.5.x (5.5.1 today), dune 3.24.2, melange 7.0.1-55, ocamlformat 0.29.0
#   opam 2.5.x (2.5.2 today) — same minor as ocaml/setup-ocaml on CI.
# Do not COPY the repo — Cursor checks out the requested revision itself.
#
# ocaml/opam minor tags resolve to the latest patch; the switch is named 5.5
# (no patch). The grep after opam install asserts the compiler is 5.5.x.
# The image repo is the local clone at /home/opam/opam-repository; pin a
# commit before opam update or the package set floats with the weekly rebuild.
#
# /usr/bin/opam on ocaml/opam is the oldest supported client (2.1) so
# opam-repo-ci can still test old solvers. Latest stable is already on
# disk as /usr/bin/opam-2.5. :with-dev-setup is 2.2+; if we leave the
# default on 2.1, `opam install --with-dev-setup` and `{with-dev-setup}`
# filters do not exist.

FROM ocaml/opam:ubuntu-24.04-ocaml-5.5

# The ocaml/opam base already exports OPAMYES=1 and
# OPAMCONFIRMLEVEL=unsafe-yes. Do not re-declare them here.
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
# Point /usr/bin/opam at 2.5 before any opam command so the root format
# upgrades once (2.1 → 2.2 layout) and later RUNs see --with-dev-setup.
# --disable-sandboxing matches the ocaml/opam root and setup-ocaml on CI;
# --reinit would otherwise write wrap-*-commands → sandbox.sh when bwrap works.
# The base image already exports OPAMYES / OPAMCONFIRMLEVEL (see above). They are
# repeated on this RUN only so it stays non-interactive if a base rebuild drops them.
RUN sudo ln -f /usr/bin/opam-2.5 /usr/bin/opam \
 && opam --version | grep -Eq '^2\.5\.[0-9]+$' \
 && git -C /home/opam/opam-repository fetch --depth 1 origin b99de6133afc2d00ac41252541e04606932e62f7 \
 && git -C /home/opam/opam-repository reset -q --hard FETCH_HEAD \
 && OPAMYES=1 OPAMCONFIRMLEVEL=unsafe-yes opam init --reinit -ni --disable-sandboxing \
 && test "$(grep -c 'sandbox.sh' /home/opam/.opam/config || true)" = 0 \
 && opam repository list | grep -q '/home/opam/opam-repository' \
 && OPAMYES=1 OPAMCONFIRMLEVEL=unsafe-yes opam update \
 && OPAMYES=1 OPAMCONFIRMLEVEL=unsafe-yes opam install -y dune.3.24.2 ocamlformat.0.29.0 melange.7.0.1-55 \
 && ocaml -vnum | grep -Eq '^5\.5\.[0-9]+$'
