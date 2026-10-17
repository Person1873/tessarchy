# GitHub review — 2026-10-17

Release scope: the tested `build/live-iso` branch at
`aa8b59a73a8d5d6b1d3fab6c17272e68e0bfac58`. The owner explicitly chose
to leave collaborators’ open pull requests unchanged.

## Observed repository state

- 24 open pull requests, including 8 drafts; no open issues at review time.
- Current source checks pass locally: 17 Python tests and 19 Qt Quick results,
  Lua syntax, Hyprland configuration verification and QML lint.
- Existing ISO and Pages workflows succeeded on the preceding development source.
- Some fork workflows require maintainer approval; missing checks are not passes.
- No contributor pull request was merged, rewritten, approved or closed.

This is a status inventory, not a code-quality approval of pending contributions.

## Pending work

| PR | Change | Base branch | State |
| --- | --- | --- | --- |
| [#1](https://github.com/thediamondsaint/tessarchy/pull/1) | Add Quiet Edge mobile shell, card switching and pull-down controls | `main` | Draft |
| [#2](https://github.com/thediamondsaint/tessarchy/pull/2) | Harden install tooling and fill the app drawer from desktop entries | `main` | Open |
| [#3](https://github.com/thediamondsaint/tessarchy/pull/3) | Add a desktop workspace strip, focused-window title and desktop keybindings | `feat/phone-shell` | Open |
| [#4](https://github.com/thediamondsaint/tessarchy/pull/4) | Bundle fish as the live user's login shell | `feat/phone-shell` | Open |
| [#5](https://github.com/thediamondsaint/tessarchy/pull/5) | Harden the live rootfs identity and runtime defaults | `feat/phone-shell` | Open |
| [#6](https://github.com/thediamondsaint/tessarchy/pull/6) | Make the source checks portable and add a checks workflow | `feat/phone-shell` | Open |
| [#7](https://github.com/thediamondsaint/tessarchy/pull/7) | Integrate squeekboard as an optional on-screen keyboard | `feat/phone-shell` | Draft |
| [#8](https://github.com/thediamondsaint/tessarchy/pull/8) | Keep Phone/Tablet apps maximized and fit oversized dialogs | `feat/phone-shell` | Draft |
| [#9](https://github.com/thediamondsaint/tessarchy/pull/9) | Carry the system theme through shell, keyboard and apps (Omarchy themes) | `feat/phone-shell` | Draft |
| [#10](https://github.com/thediamondsaint/tessarchy/pull/10) | Touch file dialogs on Phone/Tablet (portal backend + GTK3 module) | `feat/phone-shell` | Draft |
| [#11](https://github.com/thediamondsaint/tessarchy/pull/11) | On-screen keyboard rows fit 48 logical px | `feat/phone-shell` | Draft |
| [#12](https://github.com/thediamondsaint/tessarchy/pull/12) | Tablet split: two apps side by side with touch controls | `feat/phone-shell` | Draft |
| [#13](https://github.com/thediamondsaint/tessarchy/pull/13) | Add notification pop-ups and an alert center | `feat/phone-shell` | Open |
| [#14](https://github.com/thediamondsaint/tessarchy/pull/14) | Add full-screen screenshots from Quick controls and the Print key | `feat/phone-shell` | Open |
| [#15](https://github.com/thediamondsaint/tessarchy/pull/15) | Add MPRIS media controls to the status bar and Quick controls | `feat/phone-shell` | Open |
| [#16](https://github.com/thediamondsaint/tessarchy/pull/16) | Show live window previews in the app switcher | `feat/phone-shell` | Open |
| [#17](https://github.com/thediamondsaint/tessarchy/pull/17) | Add a PipeWire audio panel to quick controls | `feat/phone-shell` | Open |
| [#18](https://github.com/thediamondsaint/tessarchy/pull/18) | Add a battery and power-mode panel to quick controls | `feat/phone-shell` | Open |
| [#19](https://github.com/thediamondsaint/tessarchy/pull/19) | Add display controls: brightness helper, keys and a night-light toggle | `feat/phone-shell` | Open |
| [#20](https://github.com/thediamondsaint/tessarchy/pull/20) | Keep the keyboard hidden while a shell page is open | `feat/phone-shell` | Draft |
| [#21](https://github.com/thediamondsaint/tessarchy/pull/21) | Blank the idle panel after five minutes with hypridle | `feat/phone-shell` | Open |
| [#22](https://github.com/thediamondsaint/tessarchy/pull/22) | Rotate the focused display from Settings in 90° steps | `feat/phone-shell` | Open |
| [#23](https://github.com/thediamondsaint/tessarchy/pull/23) | Connect Wi-Fi from Quick controls through NetworkManager | `feat/phone-shell` | Open |
| [#24](https://github.com/thediamondsaint/tessarchy/pull/24) | Add Bluetooth quick controls to the shell | `feat/phone-shell` | Open |

Contributors’ draft features and unmerged proposals are not included in Alpha 2.
They require individual source review, relevant checks and runtime validation
before integration; the release does not claim those features.
