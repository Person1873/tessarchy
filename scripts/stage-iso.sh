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
cat "$root/iso/packages.x86_64" >> "$profile/packages.x86_64"
sort -u -o "$profile/packages.x86_64" "$profile/packages.x86_64"
# Keep the installed releng bootloader layout, mkinitcpio hooks and permissions.
cat >> "$profile/profiledef.sh" <<'PROFILE'

# Tessarchy overrides: stock releng boot placeholders and install_dir retained.
iso_name="tessarchy"
iso_label="TESSARCHY_$(date +%Y%m)"
iso_publisher="Tessarchy prototype"
iso_application="Tessarchy live development session"
iso_version="0.1.0-$(date +%Y%m%d)"
arch="x86_64"
airootfs_image_tool_options=('-comp' 'zstd' '-Xcompression-level' '3' '-b' '1M')
file_permissions+=(
  ["/etc/shadow"]="0:0:400"
  ["/home/tess"]="1000:1000:750"
  ["/home/tess/.bash_profile"]="1000:1000:644"
  ["/usr/bin/start-tessarchy"]="0:0:755"
  ["/usr/bin/tessera-shell"]="0:0:755"
)
PROFILE
airoot=$profile/airootfs
mkdir -p "$airoot/usr/share/tessarchy/session" "$airoot/usr/bin" "$airoot/usr/share/wayland-sessions"
cp -R -- "$root/shell" "$airoot/usr/share/tessarchy/"
cp -- "$root/session/hyprland.lua" "$airoot/usr/share/tessarchy/session/"
install -m755 "$root/session/start-tessarchy" "$root/session/tessera-shell" "$airoot/usr/bin/"
install -m644 "$root/session/tessarchy.desktop" "$airoot/usr/share/wayland-sessions/"
cp -a "$root/iso/airootfs/." "$airoot/"
# Create the live user via systemd-sysusers, preserving base account databases.
mkdir -p "$airoot/home/tess"
cp "$root/iso/airootfs/etc/skel/.bash_profile" "$airoot/home/tess/.bash_profile"
# Releng may enable SSH for rescue. Keep network services out of this prototype.
find "$airoot/etc/systemd/system" -type l -name 'sshd.service' -delete
printf 'Tessarchy live prototype. tty1: tess autologin; no password login.\n' > "$airoot/etc/issue"
echo "Profile staged: $profile"
echo "Review it, then run ./scripts/build-iso.sh"
