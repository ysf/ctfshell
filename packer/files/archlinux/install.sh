#!/bin/bash

# required env:
# - ARCH_RELEASE
# - KEYMAP
# - LOCALE
# - TIMEZONE
#
# optional env
# - EXTRA_PACKAGES

set -euo pipefail

readonly ARCH_MIRROR='https://geo.mirror.pkgbuild.com'

# obtain arch tools
if [ "${ARCH_RELEASE}" = "latest" ]; then
  readonly ARCH_ISO="archlinux-bootstrap-x86_64.tar.zst"
  #echo "DEBUG: Downloading from: ${ARCH_MIRROR}/iso/latest/${ARCH_ISO}"
  curl --location -o "${ARCH_ISO}" "${ARCH_MIRROR}/iso/latest/${ARCH_ISO}"
  #echo "DEBUG: Downloading signature from: ${ARCH_MIRROR}/iso/latest/${ARCH_ISO}.sig"
  curl --location -o "${ARCH_ISO}.sig" "${ARCH_MIRROR}/iso/latest/${ARCH_ISO}.sig"
else
  readonly ARCH_ISO="archlinux-bootstrap-${ARCH_RELEASE//-/.}-x86_64.tar.gz"
  #echo "DEBUG: Downloading from: ${ARCH_MIRROR}/iso/${ARCH_RELEASE//-/.}/${ARCH_ISO}"
  curl --location -o "${ARCH_ISO}" "${ARCH_MIRROR}/iso/${ARCH_RELEASE//-/.}/${ARCH_ISO}"
  #echo "DEBUG: Downloading signature from: ${ARCH_MIRROR}/iso/${ARCH_RELEASE//-/.}/${ARCH_ISO}.sig"
  curl --location -o "${ARCH_ISO}.sig" "${ARCH_MIRROR}/iso/${ARCH_RELEASE//-/.}/${ARCH_ISO}.sig"
fi

# import and trust the arch linux developer key
gpg --batch --import /tmp/key-*.gpg
echo '3E80CA1A8B89F69CBA57D98A76A5EF9054449A5C:6:' | gpg --batch --import-ownertrust

gpg --verify "./${ARCH_ISO}.sig" "./${ARCH_ISO}"
if [[ "${ARCH_ISO}" == *.tar.zst ]]; then
  tar --zstd -xf "./${ARCH_ISO}"
else
  tar xzf "./${ARCH_ISO}"
fi
rm "./${ARCH_ISO}" # save ramfs memory

# prepare mounts
readonly iso='/root/root.x86_64'
mount --bind "$iso" "$iso" # XXX arch-chroot needs / to be a mountpoint
mount --bind /mnt "$iso/mnt"

# install base
"${iso}/bin/arch-chroot" "$iso" <<EOF
set -euo pipefail

# pacstrap
echo 'Server = ${ARCH_MIRROR}/\$repo/os/\$arch' > /etc/pacman.d/mirrorlist
pacman-key --init
pacman-key --populate archlinux
pacstrap /mnt base linux grub nano btrfs-progs openssh curl jq python-yaml $EXTRA_PACKAGES

# fstab
genfstab -U /mnt > /mnt/etc/fstab
echo 'proc /proc proc defaults,hidepid=2 0 0' >> /mnt/etc/fstab
EOF

# configure base
"${iso}/bin/arch-chroot" /mnt <<EOF
set -euo pipefail

# time
systemctl enable systemd-timesyncd
ln -sf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime
hwclock --systohc

# locale
echo 'KEYMAP=${KEYMAP}' > /etc/vconsole.conf
echo '${LOCALE} UTF-8' > /etc/locale.gen
echo 'LANG=${LOCALE}' > /etc/locale.conf
locale-gen

# network
mkdir -p /root/.ssh/
systemctl enable systemd-networkd systemd-resolved sshd
cat > /etc/systemd/network/default.network <<EOF2
[Match]
Name=en*
[Network]
DHCP=yes
EOF2

# grub
grub-install /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg /dev/sda

# hcloud
# these services were uploaded by packer beforehand
for i in /etc/systemd/system/hcloud*.service; do
  systemctl enable "\$i"
done

# misc
systemctl set-default multi-user.target
usermod -L root
echo 'archlinux' > /etc/hostname

EOF

# clean up
rm /mnt/root/.bash_history
rm -r /mnt/var/cache/*
