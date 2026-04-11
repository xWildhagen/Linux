#!/usr/bin/env bash

set -eou pipefail

if [[ "${EUID}" -ne 0 ]]; then
    echo -e "❌ Error: Run as root or with sudo!"
    exit 1
fi

# ==========================================
# VARIABLES
# ==========================================
DRIVE="/dev/nvme0n1"

HOSTNAME="cachyos"
USERNAME="wildhagen"
PASSWORD="wildhagen"

TIMEZONE="Europe/Oslo"
LOCALE="nb_NO.UTF-8"
LOCALE_FALLBACK="en_GB.UTF-8"
KEYMAP="no-latin1"
CONSOLE_FONT="ter-v24b"

KERNEL="linux-cachyos"

BOOT_LABEL="CachyOS"

EFI_SIZE_MIB=4096

BTRFS_MOUNT_OPTS="noatime,compress=zstd"
BTRFS_SUBVOLUMES=("@" "@home" "@snapshots" "@log" "@cache")

PACKAGES=(
    base base-devel "${KERNEL}" "${KERNEL}-headers" linux-firmware
    networkmanager limine efibootmgr sudo nano btrfs-progs
    amd-ucode intel-ucode
    chwd
    zram-generator
    bluez bluez-utils
    terminus-font ttf-jetbrains-mono-nerd
    plasma plasma-login-manager konsole firefox
    cachyos-keyring cachyos-mirrorlist
)

# ==========================================
# HELPERS
# ==========================================
cleanup() {
    echo "⏳ Unmounting filesystems..."
    sync
    umount -R /mnt 2>/dev/null || umount -lR /mnt 2>/dev/null || true
}

get_partition_names() {
    local drive="$1"

    if [[ "${drive}" == *"nvme"* ]] || [[ "${drive}" == *"mmcblk"* ]]; then
        PART_EFI="${drive}p1"
        PART_ROOT="${drive}p2"
    else
        PART_EFI="${drive}1"
        PART_ROOT="${drive}2"
    fi
}

partition_drive() {
    local drive="$1"

    echo "⏳ Wiping and partitioning ${drive}..."
    swapoff -a 2>/dev/null || true
    umount -f "${drive}"* 2>/dev/null || true
    wipefs -af "${drive}"
    parted -s "${drive}" mklabel gpt
    local efi_end=$(( EFI_SIZE_MIB + 1 ))
    parted -s "${drive}" mkpart EFI fat32 1MiB "${efi_end}MiB"
    parted -s "${drive}" set 1 esp on
    parted -s "${drive}" mkpart ROOT btrfs "${efi_end}MiB" 100%
}

format_partitions() {
    echo "⏳ Formatting partitions..."
    mkfs.fat -F32 "${PART_EFI}"
    mkfs.btrfs -f "${PART_ROOT}"
}

mount_partitions() {
    echo "⏳ Mounting partitions..."
    mount "${PART_ROOT}" /mnt

    echo "⏳ Creating btrfs subvolumes..."
    for subvol in "${BTRFS_SUBVOLUMES[@]}"; do
        btrfs subvolume create "/mnt/${subvol}"
    done
    umount /mnt

    echo "⏳ Mounting btrfs subvolumes..."
    mount -o "${BTRFS_MOUNT_OPTS}",subvol=@ "${PART_ROOT}" /mnt
    mkdir -p /mnt/{home,.snapshots,var/log,var/cache,boot}
    mount -o "${BTRFS_MOUNT_OPTS}",subvol=@home "${PART_ROOT}" /mnt/home
    mount -o "${BTRFS_MOUNT_OPTS}",subvol=@snapshots "${PART_ROOT}" /mnt/.snapshots
    mount -o "${BTRFS_MOUNT_OPTS}",subvol=@log "${PART_ROOT}" /mnt/var/log
    mount -o "${BTRFS_MOUNT_OPTS}",subvol=@cache "${PART_ROOT}" /mnt/var/cache
    mount "${PART_EFI}" /mnt/boot
}

install_base_system() {
    echo "⏳ Pacstrapping CachyOS base and KDE Plasma..."
    pacstrap -K /mnt "${PACKAGES[@]}"

    echo "⏳ Injecting CachyOS repositories into the new system..."
    cp /etc/pacman.conf /mnt/etc/pacman.conf
}

generate_fstab() {
    echo "⏳ Generating fstab..."
    genfstab -U /mnt >> /mnt/etc/fstab
}

configure_system() {
    local hostname="$1"
    local username="$2"
    local password="$3"
    local timezone="$4"

    echo "⏳ Chrooting into the new system to finalize configuration..."

    arch-chroot /mnt /bin/bash <<EOF
set -eou pipefail

# Timezone & Clock
ln -sf "/usr/share/zoneinfo/${timezone}" /etc/localtime
hwclock --systohc

# Locale
cat <<EOL > /etc/locale.gen
${LOCALE} UTF-8
${LOCALE_FALLBACK} UTF-8
EOL
locale-gen
echo "LANG=${LOCALE}" > /etc/locale.conf

# Keyboard & Console Font
cat <<VCONSOLE > /etc/vconsole.conf
KEYMAP=${KEYMAP}
FONT=${CONSOLE_FONT}
VCONSOLE

# Hostname & Hosts file
echo "${hostname}" > /etc/hostname
cat <<EOT >> /etc/hosts
127.0.0.1   localhost
::1         localhost
127.0.1.1   ${hostname}.localdomain   ${hostname}
EOT

# Root Password
echo "root:${password}" | chpasswd

# Create Standard User
useradd -m -G wheel -s /bin/bash "${username}"
echo "${username}:${password}" | chpasswd

# Enable Sudo for wheel group users
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

# Initramfs (btrfs hook)
sed -i 's/^MODULES=()/MODULES=(btrfs)/' /etc/mkinitcpio.conf
mkinitcpio -P

# ZRAM Swap
mkdir -p /etc/systemd
cat <<ZRAM > /etc/systemd/zram-generator.conf
[zram0]
zram-size = ram / 2
compression-algorithm = zstd
ZRAM

# GPU Drivers (auto-detect AMD/NVIDIA)
chwd -a

# Bootloader Configuration (Limine)
mkdir -p /boot/EFI/limine
cp /usr/share/limine/BOOTX64.EFI /boot/EFI/limine/

ROOT_UUID="\$(blkid -s UUID -o value "${PART_ROOT}")"
cat <<LIMINE > /boot/limine.conf
timeout: 5

:${BOOT_LABEL}
protocol: linux
path: boot():/vmlinuz-${KERNEL}
cmdline: root=UUID=\${ROOT_UUID} rw rootflags=subvol=@ zswap.enabled=0 loglevel=3
module_path: boot():/initramfs-${KERNEL}.img
LIMINE

efibootmgr --create --disk ${DRIVE} --part 1 --label "${BOOT_LABEL}" --loader '\EFI\limine\BOOTX64.EFI' --unicode

# Enable Services
systemctl enable NetworkManager
systemctl enable plasmalogin
systemctl enable fstrim.timer
systemctl enable bluetooth
EOF
}

# ==========================================
# MAIN
# ==========================================
main() {
    echo "⚠️ WARNING: This will COMPLETELY WIPE ${DRIVE} in 5 seconds. Press Ctrl+C to abort."
    sleep 5

    trap cleanup EXIT ERR INT

    get_partition_names "${DRIVE}"
    partition_drive "${DRIVE}"
    format_partitions
    mount_partitions
    install_base_system
    generate_fstab
    configure_system "${HOSTNAME}" "${USERNAME}" "${PASSWORD}" "${TIMEZONE}"

    trap - EXIT ERR INT

    echo "✅ Installation complete! Unmounting file systems..."
    sync
    sleep 1
    umount -R /mnt || umount -lR /mnt

    echo "🎉 Done! You can now type 'reboot' and remove your USB."
}

main