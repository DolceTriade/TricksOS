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
    /usr/bin/systemd-escape
    /usr/bin/systemd-analyze
    /usr/bin/journalctl
    /usr/bin/dbus-daemon
    /usr/bin/dbus-send

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

    /usr/lib/systemd/system-generators/systemd-gpt-auto-generator

    /usr/bin/ostree
    /usr/lib/ostree/ostree-prepare-root
    /usr/lib/ostree/ostree-remount

    /usr/lib/udev/scsi_id
    /usr/lib/udev/ata_id
)

LIBS=(
    /usr/lib/libcryptsetup.so.12
    /usr/lib/libcap.so.2
    /lib/ld-linux-x86-64.so.2
)

FILES=(
    /usr/bin/fsck.btrfs
    /usr/lib/systemd/system/apparmor.service
    /usr/lib/systemd/system/getty@.service
    /usr/lib/systemd/system/basic.target
    /usr/lib/systemd/system/blockdev@.target
    /usr/lib/systemd/system/bluetooth.target
    /usr/lib/systemd/system/boot-complete.target
    /usr/lib/systemd/system/chrony.service
    /usr/lib/systemd/system/console-getty.service
    /usr/lib/systemd/system/container-getty@.service
    /usr/lib/systemd/system/cryptsetup-pre.target
    /usr/lib/systemd/system/cryptsetup.target
    /usr/lib/systemd/system/reboot.target
    /usr/lib/systemd/system/systemd-hostnamed.service
    /usr/lib/systemd/system/systemd-localed.service
    /usr/lib/systemd/system/systemd-logind.service
    /usr/lib/systemd/system/systemd-oomd.service
    /usr/lib/systemd/system/systemd-portabled.service
    /usr/lib/systemd/system/systemd-timedated.service
    /usr/lib/systemd/system/dbus.service
    /usr/lib/systemd/system/dbus.socket
    /usr/lib/systemd/system/debug-shell.service
    /usr/lib/systemd/system/multi-user.target
    /usr/lib/systemd/system/dev-hugepages.mount
    /usr/lib/systemd/system/dev-mqueue.mount
    /usr/lib/systemd/system/docker.service
    /usr/lib/systemd/system/docker.socket
    /usr/lib/systemd/system/emergency.service
    /usr/lib/systemd/system/emergency.target
    /usr/lib/systemd/system/exit.target
    /usr/lib/systemd/system/factory-reset.target
    /usr/lib/systemd/system/final.target
    /usr/lib/systemd/system/first-boot-complete.target
    /usr/lib/systemd/system/fstrim.service
    /usr/lib/systemd/system/fstrim.timer
    /usr/lib/systemd/system/getty-pre.target
    /usr/lib/systemd/system/getty.target
    /usr/lib/systemd/system/getty@.service
    /usr/lib/systemd/system/graphical.target
    /usr/lib/systemd/system/halt.target
    /usr/lib/systemd/system/initrd-cleanup.service
    /usr/lib/systemd/system/initrd-fs.target
    /usr/lib/systemd/system/initrd-parse-etc.service
    /usr/lib/systemd/system/initrd-root-device.target
    /usr/lib/systemd/system/initrd-root-device.target.wants
    /usr/lib/systemd/system/initrd-root-fs.target
    /usr/lib/systemd/system/initrd-root-fs.target.wants
    /usr/lib/systemd/system/initrd-switch-root.service
    /usr/lib/systemd/system/initrd-switch-root.target
    /usr/lib/systemd/system/initrd-udevadm-cleanup-db.service
    /usr/lib/systemd/system/initrd-usr-fs.target
    /usr/lib/systemd/system/initrd.target
    /usr/lib/systemd/system/integritysetup-pre.target
    /usr/lib/systemd/system/integritysetup.target
    /usr/lib/systemd/system/kexec.target
    /usr/lib/systemd/system/kmod-static-nodes.service
    /usr/lib/systemd/system/local-fs-pre.target
    /usr/lib/systemd/system/local-fs.target
    /usr/lib/systemd/system/local-fs.target.wants
    /usr/lib/systemd/system/modprobe@.service
    /usr/lib/systemd/system/multi-user.target
    /usr/lib/systemd/system/multi-user.target.wants
    /usr/lib/systemd/system/network-online.target
    /usr/lib/systemd/system/network-pre.target
    /usr/lib/systemd/system/network.target
    /usr/lib/systemd/system/nss-lookup.target
    /usr/lib/systemd/system/nss-user-lookup.target
    /usr/lib/systemd/system/pam_namespace.service
    /usr/lib/systemd/system/paths.target
    /usr/lib/systemd/system/polkit.service
    /usr/lib/systemd/system/poweroff.target
    /usr/lib/systemd/system/printer.target
    /usr/lib/systemd/system/proc-sys-fs-binfmt_misc.automount
    /usr/lib/systemd/system/proc-sys-fs-binfmt_misc.mount
    /usr/lib/systemd/system/quotaon.service
    /usr/lib/systemd/system/reboot.target
    /usr/lib/systemd/system/remote-cryptsetup.target
    /usr/lib/systemd/system/remote-fs-pre.target
    /usr/lib/systemd/system/remote-fs.target
    /usr/lib/systemd/system/remote-veritysetup.target
    /usr/lib/systemd/system/rescue.service
    /usr/lib/systemd/system/rescue.target
    /usr/lib/systemd/system/rpcbind.target
    /usr/lib/systemd/system/serial-getty@.service
    /usr/lib/systemd/system/shutdown.target
    /usr/lib/systemd/system/sigpwr.target
    /usr/lib/systemd/system/sleep.target
    /usr/lib/systemd/system/slices.target
    /usr/lib/systemd/system/smartcard.target
    /usr/lib/systemd/system/smartd.service
    /usr/lib/systemd/system/sockets.target
    /usr/lib/systemd/system/sockets.target.wants
    /usr/lib/systemd/system/sound.target
    /usr/lib/systemd/system/sshd.service
    /usr/lib/systemd/system/suspend.target
    /usr/lib/systemd/system/swap.target
    /usr/lib/systemd/system/sys-fs-fuse-connections.mount
    /usr/lib/systemd/system/sys-kernel-config.mount
    /usr/lib/systemd/system/sys-kernel-debug.mount
    /usr/lib/systemd/system/sys-kernel-tracing.mount
    /usr/lib/systemd/system/sysinit.target
    /usr/lib/systemd/system/sysinit.target.wants
    /usr/lib/systemd/system/syslog.socket
    /usr/lib/systemd/system/system-update-cleanup.service
    /usr/lib/systemd/system/system-update-pre.target
    /usr/lib/systemd/system/system-update.target
    /usr/lib/systemd/system/systemd-ask-password-console.path
    /usr/lib/systemd/system/systemd-ask-password-console.service
    /usr/lib/systemd/system/systemd-ask-password-wall.path
    /usr/lib/systemd/system/systemd-ask-password-wall.service
    /usr/lib/systemd/system/systemd-binfmt.service
    /usr/lib/systemd/system/systemd-bless-boot.service
    /usr/lib/systemd/system/systemd-boot-check-no-failures.service
    /usr/lib/systemd/system/systemd-boot-system-token.service
    /usr/lib/systemd/system/systemd-boot-update.service
    /usr/lib/systemd/system/systemd-bootchart.service
    /usr/lib/systemd/system/systemd-exit.service
    /usr/lib/systemd/system/systemd-fsck-root.service
    /usr/lib/systemd/system/systemd-fsck@.service
    /usr/lib/systemd/system/systemd-halt.service
    /usr/lib/systemd/system/systemd-homed-activate.service
    /usr/lib/systemd/system/systemd-homed.service
    /usr/lib/systemd/system/systemd-hostnamed.service
    /usr/lib/systemd/system/systemd-journal-catalog-update.service
    /usr/lib/systemd/system/systemd-journal-flush.service
    /usr/lib/systemd/system/systemd-journald-audit.socket
    /usr/lib/systemd/system/systemd-journald-dev-log.socket
    /usr/lib/systemd/system/systemd-journald-varlink@.socket
    /usr/lib/systemd/system/systemd-journald.service
    /usr/lib/systemd/system/systemd-journald.socket
    /usr/lib/systemd/system/systemd-journald@.service
    /usr/lib/systemd/system/systemd-journald@.socket
    /usr/lib/systemd/system/systemd-kexec.service
    /usr/lib/systemd/system/systemd-localed.service
    /usr/lib/systemd/system/systemd-logind.service
    /usr/lib/systemd/system/systemd-machine-id-commit.service
    /usr/lib/systemd/system/systemd-modules-load.service
    /usr/lib/systemd/system/systemd-network-generator.service
    /usr/lib/systemd/system/systemd-networkd-wait-online.service
    /usr/lib/systemd/system/systemd-networkd.service
    /usr/lib/systemd/system/systemd-networkd.socket
    /usr/lib/systemd/system/systemd-nspawn@.service
    /usr/lib/systemd/system/systemd-oomd.service
    /usr/lib/systemd/system/systemd-oomd.socket
    /usr/lib/systemd/system/systemd-portabled.service
    /usr/lib/systemd/system/systemd-poweroff.service
    /usr/lib/systemd/system/systemd-pstore.service
    /usr/lib/systemd/system/systemd-quotacheck.service
    /usr/lib/systemd/system/systemd-random-seed.service
    /usr/lib/systemd/system/systemd-reboot.service
    /usr/lib/systemd/system/systemd-remount-fs.service
    /usr/lib/systemd/system/systemd-repart.service
    /usr/lib/systemd/system/systemd-suspend.service
    /usr/lib/systemd/system/systemd-sysctl.service
    /usr/lib/systemd/system/systemd-sysext.service
    /usr/lib/systemd/system/systemd-sysusers.service
    /usr/lib/systemd/system/systemd-time-wait-sync.service
    /usr/lib/systemd/system/systemd-timedated.service
    /usr/lib/systemd/system/systemd-timesyncd.service
    /usr/lib/systemd/system/systemd-tmpfiles-clean.service
    /usr/lib/systemd/system/systemd-tmpfiles-clean.timer
    /usr/lib/systemd/system/systemd-tmpfiles-setup-dev.service
    /usr/lib/systemd/system/systemd-tmpfiles-setup.service
    /usr/lib/systemd/system/systemd-udev-settle.service
    /usr/lib/systemd/system/systemd-udev-trigger.service
    /usr/lib/systemd/system/systemd-udevd-control.socket
    /usr/lib/systemd/system/systemd-udevd-kernel.socket
    /usr/lib/systemd/system/systemd-udevd.service
    /usr/lib/systemd/system/systemd-update-done.service
    /usr/lib/systemd/system/systemd-user-sessions.service
    /usr/lib/systemd/system/systemd-userdbd.service
    /usr/lib/systemd/system/systemd-userdbd.socket
    /usr/lib/systemd/system/systemd-vconsole-setup.service
    /usr/lib/systemd/system/systemd-volatile-root.service
    /usr/lib/systemd/system/time-set.target
    /usr/lib/systemd/system/time-sync.target
    /usr/lib/systemd/system/timers.target
    /usr/lib/systemd/system/timers.target.wants
    /usr/lib/systemd/system/tmp.mount
    /usr/lib/systemd/system/umount.target
    /usr/lib/systemd/system/usb-gadget.target
    /usr/lib/systemd/system/user-.slice.d
    /usr/lib/systemd/system/user-runtime-dir@.service
    /usr/lib/systemd/system/user.slice
    /usr/lib/systemd/system/user@.service
    /usr/lib/systemd/system/uuidd.service
    /usr/lib/systemd/system/uuidd.socket
    /usr/lib/systemd/system/veritysetup-pre.target
    /usr/lib/systemd/system/veritysetup.target
    /usr/lib/systemd/system/xfs_scrub@.service
    /usr/lib/systemd/system/xfs_scrub_all.service
    /usr/lib/systemd/system/xfs_scrub_all.timer
    /usr/lib/systemd/system/xfs_scrub_fail@.service

    /usr/lib/udev/rules.d
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

declare -A SYMLINKS=(
    ["/etc/mtab"]=/proc/mounts
    ["/usr/lib/systemd/system/sysinit.target.wants/systemd-udev-settle.service"]=../systemd-udev-settle.service
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
        cp -a "${path}" "${dest}"
    done
}

add_symlinks() {
    for sym in "${!SYMLINKS[@]}"; do
        local dir; dir="${OUTPUT}$(dirname "${sym}")"
        mkdir -p "${dir}"
        pushd "${dir}"
        ln -s "${SYMLINKS[$sym]}" "${OUTPUT}${sym}"
        popd
    done
}

main() {
    rm -rf "${OUTPUT}" "${STAGING}"
    mkdir -p "${OUTPUT}" "${STAGING}"
    rm -f "${SCRIPT_DIR}"/initramfs.img

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

    add_symlinks

    pushd "${OUTPUT}"
    find . -name .keep -delete
    find | cpio -o -H newc | zstd --ultra -10 -o "${SCRIPT_DIR}/initramfs.img"
    popd
}

main
