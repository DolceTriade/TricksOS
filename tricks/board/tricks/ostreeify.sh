#!/bin/bash
set -e
set -o pipefail
set -x
readonly INITRAMFS_PATH="${BR2_EXTERNAL_tricks_PATH}/../initramfs"

readonly KERN_VER="$(ls -1 "${TARGET_DIR}/usr/lib/modules" | head -n 1)"

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
    cp "${INITRAMFS_PATH}/initramfs.img" "${TARGET_DIR}/usr/lib/modules/${KERN_VER}"
}

main() {
    # Let's generate our initramfs
    gen_initramfs

    # Move kernel to /usr
    ls "${TARGET_DIR}"/usr/lib/modules/*/
    cp "${TARGET_DIR}"/boot/bzImage "${TARGET_DIR}/usr/lib/modules/${KERN_VER}/vmlinuz"

    # Clean up stuff
    for d in "${DELETE[@]}"; do
        rm -rf "${TARGET_DIR}"/"${d}"
    done
    find "${TARGET_DIR}" -name .keep -delete

    mkdir -p "${TARGET_DIR}/sysroot"
    pushd "${TARGET_DIR}"
    ln -sfr sysroot/ostree ostree
    popd
}

main
