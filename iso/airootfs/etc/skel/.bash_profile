# Live prototype deliberately returns to a TTY after session exit.
if [[ -z ${DISPLAY:-} && -z ${WAYLAND_DISPLAY:-} && $(tty) == /dev/tty1 ]]; then
    printf '\nTessarchy live prototype — no secure locking or persistence.\n'
    printf 'Starting Tessera. After exit, run start-tessarchy to start again.\n'
    start-tessarchy
fi
