#!/bin/bash

set -e
set -o pipefail

SCRIPT_DIR="$(dirname "$(realpath "${0}")")"
BUILDROOT="$(realpath "${SCRIPT_DIR}"/../buildroot)"
TARGET="${BUILDROOT}/output/target"
OUTPUT="${SCRIPT_DIR}/output/initramfs"
STAGING="${SCRIPT_DIR}/output/staging"

MODULES_DIR="${TARGET}"/lib/modules/


BINS=(
    /usr/bin/mount
    /usr/bin/bash
    /usr/bin/systemd-tmpfiles
    /usr/bin/btrfs
    /usr/sbin/fsck
    /usr/sbin/fsck.ext2
    /usr/sbin/fsck.ext3
    /usr/sbin/fsck.ext4
    /usr/sbin/fsck.fat
    /usr/sbin/fsck.msdos
    /usr/sbin/fsck.vfat
    /usr/sbin/sulogin
    /usr/sbin/kexec
    /usr/bin/login
    /usr/bin/busybox
    /usr/sbin/modprobe
    /usr/sbin/insmod
    /usr/sbin/fdisk
    /usr/bin/udevadm
    /usr/bin/kmod

    /usr/bin/systemctl
    /usr/lib/systemd/systemd
    /usr/lib/systemd/systemd-fsck
    /usr/lib/systemd/systemd-udevd
    /usr/lib/systemd/systemd-sulogin-shell
    /usr/lib/systemd/systemd-journald
    /usr/lib/systemd/systemd-logind
    /usr/lib/systemd/systemd-vconsole-setup
    /usr/lib/systemd/systemd-veritysetup
    /usr/lib/systemd/systemd-volatile-root
    /usr/lib/systemd/systemd-cryptsetup
    /usr/lib/systemd/systemd-modules-load
    /usr/lib/systemd/systemd-network-generator
    /usr/lib/systemd/systemd-shutdown
    /usr/lib/systemd/systemd-sysctl

    /usr/bin/ostree
    /usr/lib/ostree/ostree-prepare-root
    /usr/lib/ostree/ostree-remount
)

LIBS=(
    /usr/lib/libcryptsetup.so.12
    /usr/lib/libcap.so.2
    /lib/ld-linux-x86-64.so.2
)

FILES=(
    /usr/bin/fsck.btrfs
)

MODULES=(
    kernel/arch/x86/crypto/**
    kernel/lib/**
    kernel/drivers/acpi/**
    kernel/drivers/crypto/**
    kernel/drivers/input/keyboard/atkbd.ko.zst
    kernel/drivers/hid/usbhid/usbhid.ko.zst
    kernel/drivers/nvme/**
    kernel/fs/btrfs/**
    kernel/fs/ext**
    kernel/fs/squashfs**
    kernel/fs/overlayfs**
    kernel/fs/*fat**
    kernel/crypto/**
    kernel/drivers/usb/host/**
    kernel/drivers/ata/ata_generic.ko.zst
    kernel/drivers/ata/ata_piix.ko.zst
    kernel/fs/fuse/fuse.ko.zst
    kernel/drivers/block/loop.ko.zst
    kernel/drivers/parport/parport.ko.zst
    kernel/drivers/parport/parport_pc.ko.zst
    kernel/drivers/ata/pata_acpi.ko.zst
    kernel/drivers/input/misc/pcspkr.ko.zst
    kernel/drivers/char/ppdev.ko.zst
    kernel/drivers/firmware/qemu_fw_cfg.ko.zst
    kernel/drivers/input/serio/serio.ko.zst
    kernel/drivers/input/serio/serio_raw.ko.zst
)

declare -A SEARCHED=()

copy_deps() {
    local elf="${1}"
    local search="${2}"
    local dest="${3}"

    if ((${SEARCHED["$(basename "${elf}")"]})); then
        return
    fi
    echo "Copying ${elf}"
    local deps; deps=($(objdump -x "${elf}" | ( grep NEEDED || true ) | awk '{print $2}'))
    SEARCHED["$(basename "${elf}")"]=1
    mkdir -p "$(dirname "${dest}${elf#${TARGET}}")"
    cp "${TARGET%/}${elf#${TARGET}}" "${dest}${elf#${TARGET}}"
    if [[ "${#deps}" -eq 0 ]]; then
        return
    fi
    echo "DEPS: ${deps[*]}"

    for dep in "${deps[@]}"; do
        if ((${SEARCHED["${dep}}"]})); then
            continue
        fi
        found="$(find "${search}" -name "${dep}" | head -n 1)"
        if [[ -z "${found}" ]]; then
            echo "WARN: ${dep} not found in ${search}. Skipping..." 1>&2
        fi
        to_copy="${dest}${found#${TARGET}}"
        mkdir -p "$(dirname "${to_copy}")"
        copy_deps "${found}" "${search}" "${dest}"
    done
}

copy_libs() {
    for lib in "${LIBS[@]}"; do
        copy_deps "${TARGET%/}${lib}" "${TARGET}" "${OUTPUT}"
    done
}

copy_bins() {
    for lib in "${BINS[@]}"; do
        copy_deps "${TARGET%/}${lib}" "${TARGET}" "${OUTPUT}"
    done
}

copy_modules() {
    shopt -s globstar
    for kernel in "${MODULES_DIR}"/*; do
        local dest="${kernel#${TARGET}/}"
        for mod in "${MODULES[@]}"; do
            dir="$(dirname "${OUTPUT}/${dest}/${mod}")"
            mkdir -p "${dir}"
            cp -R "${kernel}/"${mod} "${dir}"
        done
    done
    shopt -u globstar
    depmod -a -b "${OUTPUT}" 6.0.1
}

copy_files() {
    for file in "${FILES[@]}"; do
        local path="${TARGET}${file}"
        local dest="${OUTPUT}${file}"
        mkdir -p "$(dirname "${dest}")"
        cp "${path}" "${dest}"
    done
}

main() {
    rm -rf "${OUTPUT}" "${STAGING}"
    mkdir -p "${OUTPUT}" "${STAGING}"

    # Layout skeleton
    rsync -a "${SCRIPT_DIR}"/files/* "${OUTPUT}/"

    # Copy kernel modules
    copy_modules

    # Copy libraries
    copy_libs

    # Copy binaries
    copy_bins

    # Copy random files
    copy_files

    pushd "${OUTPUT}"
    find | cpio -ov -H newc | zstd --ultra -22 -o "${SCRIPT_DIR}/initrd.img"
    popd
}

main
