#! @bash@/bin/sh -e

default=$1
if test -z "$1"; then
    echo "Syntax: grub-menu-builder.sh <DEFAULT-CONFIG>"
    exit 1
fi


target=/boot/grub/menu.lst
tmp=$target.tmp

cat > $tmp << GRUBEND
# Automatically generated.  DO NOT EDIT THIS FILE!
default=0
timeout=5
GRUBEND

addEntry() {
    name="$1"
    path="$2"

    cat >> $tmp << GRUBEND
title $name
GRUBEND

    #cat $path/menu.lst >> $tmp

    grep -v "title \|default=\|timeout=" < $path/menu.lst >> $tmp
}


if test -n "$tmp"; then
    addEntry "NixOS - Default" $default
fi


# Add all generations of the system profile to the menu, in reverse
# (most recent to least recent) order.
for generation in $(
    (cd /nix/var/nix/profiles && ls -d system-*-link) \
    | sed 's/system-\([0-9]\+\)-link/\1/' \
    | sort -n -r); do
    echo $generation
    link=/nix/var/nix/profiles/system-$generation-link
    date=$(stat --printf="%y\n" $link | sed 's/\..*//')
    addEntry "NixOS - Configuration $generation ($date)" $link
        
done


cp $tmp $target