#!/usr/bin/env bash
# No host networking bridge, daemon, root access, or host disk passthrough.
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
usage() { echo "Usage: $0 init | run [ISO] | plan [ISO]"; }
operation=${1:-help}
case "$operation" in init|run|plan) ;; *) usage; exit 2;; esac
mkdir -p "$root/vm"
disk=${VM_DISK:-$root/vm/tessarchy.qcow2}
[[ $disk = /* ]] || disk=$(realpath -m -- "$disk")
if [[ $operation == init ]]; then
    [[ ! -e "$disk" ]] || { echo "Keeping existing disk: $disk"; exit 0; }
    qemu-img create -f qcow2 "$disk" 32G
    exit
fi
[[ -f "$disk" ]] || { echo "Run $0 init first" >&2; exit 1; }
iso=${2:-}
if [[ -n "$iso" ]]; then
    [[ -f "$iso" ]] || { echo "ISO not found: $iso" >&2; exit 1; }
    iso=$(realpath -- "$iso")
fi
# qemu -drive uses comma-separated options. Reject ambiguous path names.
[[ "$disk$iso" != *,* ]] || { echo "VM paths must not contain commas" >&2; exit 1; }
accel=${VM_ACCEL:-auto}
if [[ $accel == auto ]]; then
    if [[ -r /dev/kvm && -w /dev/kvm ]]; then accel=kvm; else accel=tcg; fi
fi
case "$accel" in kvm) cpu=host;; tcg) cpu=max;; *) echo "VM_ACCEL must be auto, kvm or tcg" >&2; exit 2;; esac
network=user,id=net0
if [[ -n ${VM_SSH_PORT:-} ]]; then
    if [[ ! $VM_SSH_PORT =~ ^[1-9][0-9]{3,4}$ ]] || ((VM_SSH_PORT < 1024 || VM_SSH_PORT > 65535)); then
        echo "VM_SSH_PORT must be a port between 1024 and 65535" >&2; exit 2
    fi
    network+=",hostfwd=tcp:127.0.0.1:$VM_SSH_PORT-:22"
fi
graphics=${VM_GL:-0}
case "$graphics" in
    0) gpu=virtio-vga; gl=off;;
    1) gpu=virtio-vga-gl; gl=on;;
    *) echo "VM_GL must be 0 or 1" >&2; exit 2;;
esac
audio=${VM_AUDIO:-auto}
if [[ $audio == auto ]]; then
    if [[ -S ${XDG_RUNTIME_DIR:-/run/user/$UID}/pipewire-0 ]]; then audio=pipewire
    elif [[ -S ${XDG_RUNTIME_DIR:-/run/user/$UID}/pulse/native ]]; then audio=pa
    else audio=none; fi
fi
case "$audio" in pipewire|pa|sdl|none) ;; *) echo "VM_AUDIO must be auto, pipewire, pa, sdl or none" >&2; exit 2;; esac
case "${VM_AUDIO_CODEC:-hda-output}" in hda-output|hda-duplex) ;; *) echo "VM_AUDIO_CODEC must be hda-output or hda-duplex" >&2; exit 2;; esac
cmd=(qemu-system-x86_64 -name Tessarchy -machine "q35" -accel "$accel" -cpu "$cpu"
    -m "${VM_RAM:-2048}" -smp "${VM_CPUS:-2}"
    -drive "file=$disk,format=qcow2,if=virtio"
    -device "$gpu" -display "${VM_DISPLAY:-gtk},gl=$gl"
    -device qemu-xhci -device usb-tablet
    -device virtio-rng-pci
    -audiodev "$audio,id=sound" -device "intel-hda,id=hda"
    -device "${VM_AUDIO_CODEC:-hda-output},audiodev=sound"
    -netdev "$network" -device "virtio-net-pci,netdev=net0"
    -nic none -boot "menu=on" -no-reboot)
if [[ ${VM_TOUCH:-0} == 1 ]]; then cmd+=(-device virtio-multitouch-pci); fi
if [[ ${VM_AUDIO_USB:-0} == 1 ]]; then cmd+=(-device "usb-audio,id=usb-sound,audiodev=sound"); fi
if [[ -n ${VM_QMP:-} ]]; then
    [[ $VM_QMP != *,* ]] || { echo "VM_QMP must not contain commas" >&2; exit 2; }
    cmd+=(-qmp "unix:$VM_QMP,server=on,wait=off")
fi
if [[ ${VM_SHARE:-0} == 1 ]]; then
    share=${VM_SOURCE_SHARE:-$root/build/vm-share}
    [[ -d "$share" && "$share" != *,* ]] || { echo "Run ./scripts/export-vm-source.sh first" >&2; exit 1; }
    cmd+=(-virtfs "local,path=$share,mount_tag=tessarchy,security_model=none,readonly=on")
fi
if [[ -n "$iso" ]]; then cmd+=(-cdrom "$iso" -boot "order=d,menu=on"); fi
# BIOS is the portable default. The staged live ISO retains releng BIOS + UEFI.
if [[ ${VM_UEFI:-0} == 1 ]]; then
    code=${OVMF_CODE:-/usr/share/edk2/x64/OVMF_CODE.4m.fd}
    vars=${OVMF_VARS:-/usr/share/edk2/x64/OVMF_VARS.4m.fd}
    [[ -f "$code" && -f "$vars" ]] || { echo "Install edk2-ovmf or set OVMF_CODE/OVMF_VARS" >&2; exit 1; }
    writable=$root/vm/OVMF_VARS.fd
    [[ "$code$writable" != *,* ]] || exit 2
    if [[ $operation == run && ! -e "$writable" ]]; then cp -- "$vars" "$writable"; fi
    cmd+=(-drive "if=pflash,format=raw,readonly=on,file=$code"
          -drive "if=pflash,format=raw,file=$writable")
fi
printf 'VM command:'; printf ' %q' "${cmd[@]}"; printf '\n'
[[ $operation == plan ]] && exit 0
[[ $accel != tcg ]] || echo "KVM unavailable/disabled: using slow software emulation." >&2
exec "${cmd[@]}"
