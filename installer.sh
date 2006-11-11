#! @shell@

# Syntax: installer.sh <DEVICE> <NIX-EXPR>
# (e.g., installer.sh /dev/hda1 ./my-machine.nix)

# - mount target device
# - make Nix store etc.
# - copy closure of rescue env to target device
# - register validity
# - start the "target" installer in a chroot to the target device
#   * do a nix-pull
#   * nix-env -p system-profile -i <nix-expr for the configuration>
#   * run hook scripts provided by packages in the configuration?
# - install/update grub

set -e

targetDevice="$1"
nixExpr="$2"

if test -z "$targetDevice" -o -z "$nixExpr"; then
    echo "syntax: installer.sh <targetDevice> <nixExpr>"
    exit 1
fi

nixExpr=$(readlink -f "$nixExpr")


# Make sure that the target device isn't mounted.
umount "$targetDevice" 2> /dev/null || true


# Check it.
fsck "$targetDevice"


# Mount the target device.
mountPoint=/tmp/inst-mnt
mkdir -p $mountPoint
mount "$targetDevice" $mountPoint

mkdir -p $mountPoint/dev $mountPoint/proc $mountPoint/sys $mountPoint/mnt
mount --rbind / $mountPoint/mnt
mount --bind /dev $mountPoint/dev
mount --bind /proc $mountPoint/proc
mount --bind /sys $mountPoint/sys

cleanup() {
    for i in $(grep -F "$mountPoint" /proc/mounts \
        | perl -e 'while (<>) { /^\S+\s+(\S+)\s+/; print "$1\n"; }' \
        | sort -r);
    do
        umount $i
    done
}

trap "cleanup" EXIT

mkdir -p $mountPoint/tmp
mkdir -p $mountPoint/var


# Create the necessary Nix directories on the target device, if they
# don't already exist.
mkdir -p \
    $mountPoint/nix/store \
    $mountPoint/nix/var/nix/gcroots \
    $mountPoint/nix/var/nix/temproots \
    $mountPoint/nix/var/nix/manifests \
    $mountPoint/nix/var/nix/userpool \
    $mountPoint/nix/var/nix/profiles \
    $mountPoint/nix/var/nix/db \
    $mountPoint/nix/var/log/nix/drvs


# Copy Nix to the Nix store on the target device.
echo "copying Nix to $targetDevice...."
for i in $(cat @nixClosure@); do
    echo "  $i"
    rsync -a $i $mountPoint/nix/store/
done


# Register the paths in the Nix closure as valid.  This is necessary
# to prevent them from being deleted the first time we install
# something.  (I.e., Nix will see that, e.g., the glibc path is not
# valid, delete it to get it out of the way, but as a result nothing
# will work anymore.)
for i in $(cat @nixClosure@); do
    echo $i
    echo # deriver
    echo 0 # nr of references
done \
| chroot $mountPoint @nix@/bin/nix-store --register-validity


# Create the required /bin/sh symlink; otherwise lots of things
# (notably the system() function) won't work.
mkdir -p $mountPoint/bin
ln -sf $(type -tp sh) $mountPoint/bin/sh


# Enable networking in the chroot.
mkdir -p $mountPoint/etc
cp /etc/resolv.conf $mountPoint/etc/


# Do a nix-pull to speed up building.
nixpkgsURL=http://nix.cs.uu.nl/dist/nix/nixpkgs-0.11pre6984
chroot $mountPoint @nix@/bin/nix-pull $nixpkgsURL/MANIFEST


# Build the specified Nix expression in the target store and install
# it into the system configuration profile.

#rm -rf $mountPoint/scratch
#mkdir $mountPoint/scratch
#curl $nixpkgsURL/nixexprs.tar.bz2 | tar xj -C $mountPoint/scratch
#nixpkgsName=$(cd $mountPoint/scratch && ls)

chroot $mountPoint @nix@/bin/nix-env \
    -p /nix/var/nix/profiles/system \
    -f "/mnt/$nixExpr" -i '*'
