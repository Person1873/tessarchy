#!/usr/bin/env bash
# Assemble a profile without root. Never edit /usr/share/archiso.
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
base=${ARCHISO_RELENG:-/usr/share/archiso/configs/releng}
profile=$root/build/iso-profile
[[ -f "$base/profiledef.sh" ]] || { echo "Missing releng profile: install archiso explicitly first" >&2; exit 1; }
[[ ! -e "$profile" ]] || { echo "Move/remove $profile before staging a fresh profile" >&2; exit 1; }
mkdir -p "$root/build"
cp -a -- "$base" "$profile"
# Keep releng's boot machinery, but deliberately replace its rescue-tool suite.
# Include the firmware and desktop services needed by Intel/AMD tablet testing.
sort -u "$root/iso/packages.x86_64" > "$profile/packages.x86_64"
# Keep the installed releng bootloader layout, mkinitcpio hooks and permissions.
cat >> "$profile/profiledef.sh" <<'PROFILE'

# Tessarchy overrides: stock releng boot placeholders and install_dir retained.
iso_name="tessarchy"
iso_label="TESSARCHY_$(date +%Y%m)"
iso_publisher="Tessarchy prototype"
iso_application="Tessarchy live development session"
iso_version="0.1.0-$(date +%Y%m%d)"
arch="x86_64"
kernel_params_x86_64="quiet splash loglevel=3 systemd.show_status=false"
airootfs_image_tool_options=('-comp' 'zstd' '-Xcompression-level' '3' '-b' '1M')
file_permissions+=(
  ["/etc/shadow"]="0:0:400"
  ["/home/tess"]="1000:1000:750"
  ["/home/tess/.bash_profile"]="1000:1000:644"
  ["/home/tess/.config/fish/config.fish"]="1000:1000:644"
  ["/usr/bin/start-tessarchy"]="0:0:755"
  ["/usr/bin/tessera-shell"]="0:0:755"
  ["/usr/bin/tessarchy-osk"]="0:0:755"
  ["/usr/bin/tessera-screenshot"]="0:0:755"
  ["/usr/bin/tessarchy-session-services"]="0:0:755"
  ["/usr/bin/tessarchy-readiness"]="0:0:755"
)
PROFILE
airoot=$profile/airootfs
mkdir -p "$airoot/usr/share/tessarchy/session" "$airoot/usr/bin" "$airoot/usr/share/wayland-sessions"
cp -R -- "$root/shell" "$airoot/usr/share/tessarchy/"
cp -R -- "$root/docs" "$airoot/usr/share/tessarchy/"
cp -- "$root/session/hyprland.lua" "$airoot/usr/share/tessarchy/session/"
install -m755 "$root/session/start-tessarchy" "$root/session/tessera-shell" "$root/session/tessarchy-osk" "$root/session/tessera-screenshot" "$root/session/tessarchy-session-services" "$root/session/tessarchy-readiness" "$airoot/usr/bin/"
install -m644 "$root/session/tessarchy.desktop" "$airoot/usr/share/wayland-sessions/"
cp -a "$root/iso/airootfs/." "$airoot/"
# Convert the supplied clip for initramfs playback; no video decoder runs at boot.
theme=$airoot/usr/share/plymouth/themes/tessarchy
python3 "$root/scripts/export-boot-assets.py" --output "$theme"
install -m644 "$root/session/boot/tessarchy.plymouth" "$root/session/boot/tessarchy.script" "$theme/"
install -Dm644 "$root/session/boot/plymouthd.conf" "$airoot/etc/plymouth/plymouthd.conf"
install -Dm644 "$root/session/boot/retain-splash.conf" "$airoot/etc/systemd/system/plymouth-quit.service.d/tessarchy.conf"
mkdir -p "$airoot/etc/mkinitcpio.conf.d"
cat > "$airoot/etc/mkinitcpio.conf.d/zz-tessarchy-plymouth.conf" <<'HOOKS'
# Keep releng hooks and add graphical startup immediately after KMS.
if [[ ! " ${HOOKS[*]} " == *" plymouth "* ]]; then
    tessarchy_boot_hooks=()
    for tessarchy_boot_hook in "${HOOKS[@]}"; do
        tessarchy_boot_hooks+=("$tessarchy_boot_hook")
        if [[ $tessarchy_boot_hook == kms ]]; then tessarchy_boot_hooks+=(plymouth); fi
    done
    HOOKS=("${tessarchy_boot_hooks[@]}")
    unset tessarchy_boot_hook tessarchy_boot_hooks
fi
HOOKS
# Releng uses zsh for its root rescue login. Our smaller package set uses Bash.
sed -i 's|^\(root:[^:]*:0:0:[^:]*:[^:]*:\).*|\1/usr/bin/bash|' "$airoot/etc/passwd"
# Create the live user via systemd-sysusers, preserving base account databases.
# The home scaffolding comes from the skel tree: Bash and fish login profiles.
mkdir -p "$airoot/home/tess"
cp -a "$root/iso/airootfs/etc/skel/." "$airoot/home/tess/"
# Releng may enable SSH for rescue. Keep network services out of this prototype.
find "$airoot/etc/systemd/system" -type l -name 'sshd.service' -delete
mkdir -p "$airoot/etc/systemd/system/multi-user.target.wants"
# Use one network manager; remove inherited releng wired-only activation links.
find "$airoot/etc/systemd/system" -type l \( -name 'systemd-networkd*' -o -name 'systemd-resolved*' -o -name 'iwd.service' \) -delete
ln -sf /usr/lib/systemd/system/NetworkManager.service "$airoot/etc/systemd/system/multi-user.target.wants/"
ln -sf /usr/lib/systemd/system/bluetooth.service "$airoot/etc/systemd/system/multi-user.target.wants/"
ln -sf /usr/lib/systemd/system/systemd-timesyncd.service "$airoot/etc/systemd/system/multi-user.target.wants/"
ln -sf /usr/lib/systemd/system/ModemManager.service "$airoot/etc/systemd/system/multi-user.target.wants/"
ln -sf /run/NetworkManager/resolv.conf "$airoot/etc/resolv.conf"
printf 'Tessarchy live prototype. tty1: tess autologin; no password login.\n' > "$airoot/etc/issue"
echo "Profile staged: $profile"
echo "Review it, then run ./scripts/build-iso.sh"
