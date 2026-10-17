# Contributing to Tessarchy

Tessarchy is in its first prototype stage. Small, focused changes and clear
reports from real VM/tablet testing are especially useful. Start with the
[architecture](docs/architecture.md), [roadmap](docs/roadmap.md), and local
[development instructions](AGENTS.md).

## Development

Clone the repository and follow the [VM setup](README.md#quick-start-use-the-basic-arch-vm).
Work inside an Arch guest; the scripts must not replace a contributor's active
Hyprland or Quickshell configuration. Dependency installation is a separate,
explicit step. Current API assumptions are Hyprland 0.56.x and Quickshell 0.3.1.

From the repository root, run:

```bash
./scripts/check.sh
```

This runs Bash/Lua syntax checks where tools are installed, workflow tests,
Hyprland configuration validation, and QML linting. It reports missing optional
tools. Passing static checks does not prove that the shell renders or that an
ISO boots. Follow the [manual checklist](docs/testing.md) for affected behavior.
Pushes that add files under `.github/workflows/` require a token or key with the
`workflow` scope; a GitHub Actions workflow runs the same script in an Arch
container when that is enabled.

## Changes and reports

Keep pull requests focused and explain the problem, resulting behavior, and
validation. Include screenshots for visual changes. State what was tested
personally and which checks remain pending. Verify Quickshell APIs and Hyprland
syntax against the installed versions or authoritative documentation.

For bugs, include the reproduction steps, expected/actual behavior, guest or
device details, display resolution/scale, package versions, and relevant error
output. Remove credentials and private information from logs before sharing.

Keep controls at least 48 logical pixels, avoid hover-only actions, preserve
application keyboard focus in navigation, and confirm destructive shell actions.
Do not describe trackpad gestures as touchscreen support or an overlay as a
secure lock screen. Track planned input-method and device work in the roadmap.

Generated VM disks, ISO images, downloaded packages, and build output stay out
of Git. The project is licensed under the [MIT License](LICENSE).

The Arch ISO fetcher defaults to the system Arch keyring. On other systems,
`ARCH_ISO_KEYRING` can point to an explicitly provisioned trusted Arch keyring;
signature verification remains mandatory. Refusal-path tests use a scratch
keyring fixture and do not download or trust an image.
