#!/bin/bash
set -e
set -o pipefail

env
pwd

readonly INITRAMFS_PATH="${BR2_EXTERNAL_tricks_PATH}/../initramfs"

DELETE=(
    /linuxrc
    /srv
    /root
    /opt
    /mnt
    /media
    /home
    /boot
    /usr/x86_64-buildroot-linux-gnu
    /usr/.crates.toml
    /usr/.crates2.json
)

gen_initramfs() {
    "${INITRAMFS_PATH}"/mkinitramfs.sh
    mv "${INITRAMFS_PATH}"/initrd.img "${TARGET_DIR}"/usr/lib/modules/*/
}

main() {
    # Let's generate our initramfs
    gen_initramfs

    # Move kernel to /usr
    rm -f "${TARGET_DIR}"/usr/lib/modules/*/bzImage || true
    mv -fu "${TARGET_DIR}"/boot/bzImage "${TARGET_DIR}"/usr/lib/modules/*/

    # Clean up stuff
    for d in "${DELETE[@]}"; do
        rm -rf "${TARGET_DIR}"/"${d}"
    done
    find "${TARGET_DIR}" -name .keep -delete
}

main
