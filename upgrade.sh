#! /bin/sh
set -e
nix-env -p /nix/var/nix/profiles/system -f system-configuration.nix -i -A systemConfiguration
/nix/var/nix/profiles/system/bin/switch-to-configuration