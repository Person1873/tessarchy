# Native shutdown repair overlay — partial implementation

This directory contains the first native components of the shutdown repair.
It is not installed by the Tessarchy package and is not a completed compositor
shutdown fix.

## Implemented

- `ScopedReadable.hpp`: event-loop-owned registrations with move-only cancellation
  handles, monotonic registration IDs and weak manager identity. Invalid FDs,
  poll errors and registration failures are explicit results. Readable completion
  takes/detaches its record before notification. Error/hangup takes precedence over
  readability. Closing the registry detaches its map before destroying closures,
  so closure destruction can safely cancel peers.
- `event-loop.patch`: adds this API to the actual `CEventLoopManager`, without
  changing ordinary `doOnReadable` callers (including eventfd-backed timelines).
- `TerminalDelivery.hpp`: shared per-request identity, revocation, metadata while
  pending, and terminal consumption before notification. Callback state stays
  alive if notification destroys its owner.
- `terminal-delivery.patch`: binds ext-image-copy-capture completion to the
  specific frame resource rather than raw owner `this` or a mutable current-frame
  member. Cursor callback/returned-error paths share one terminal state. Capture
  is marked requested before native share, terminal resources ignore subsequent
  non-destroy requests, and native ordinary-frame completion commits copied state
  and takes its callback before invoking it.

These changes do **not** yet make parent-session destruction preserve outstanding
child-frame native state. They also do not solve GPU resource retirement or the
screenshare-manager/compositor shutdown dependency order.

## Verify without starting a compositor

Set `CHECKOUT` to this checkout and `HYPRLAND_SOURCE` to the matching configured
Hyprland source tree with `build/compile_commands.json`, then run:

```sh
python3 "$CHECKOUT/tests/native-fit/build-core.py" --source "$HYPRLAND_SOURCE"
python3 "$CHECKOUT/tests/native-fit/verify-core-controls.py"
```

The first command compiles and executes the real C++ primitives under ASan/UBSan,
using libwayland-server event loops, eventfd and pipes. It then creates a private
source overlay, applies the combined patch with `git apply --check`, and runs the
actual configured compiler's syntax checks for `EventLoopManager.cpp`,
`ImageCopyCapture.cpp` and `ScreenshareFrame.cpp`. The original five patched input
files are hashed before/after. This does not build/link the full compositor.

Output, combined `native-shutdown.patch`, source/header/patch hashes and a success
receipt live under `build/native-fit/core-shutdown`. The receipt is removed before
each invocation, so a failed run cannot retain an earlier green receipt.

The second command compiles deliberately broken **scratch copies** of the two
headers. It requires the map-clear variant to fail with the specific ASan
use-after-free in peer cancellation, and the non-consuming terminal variant to
fail the duplicate-delivery assertion. An unrelated error or compiler failure is
not accepted as RED. Production header hashes must remain unchanged. Neither
command launches Hyprland, a plugin, a GUI, or a GPU workload.

Latest execution: 14 waiter cases and 8 terminal-delivery cases passed; both RED
controls rejected their defect; all three actual compositor translation units
passed syntax checks. No compositor runtime acceptance is claimed.

## Continue implementation

1. Add renderer-owned submitted-work records: GPU/source locks, destination and
   required render-target lifetimes must be independent of protocol completion.
   Scoped waiter closures must not be the last owner of in-flight GPU resources.
2. Settle those records against checked native fence status under one shutdown
   deadline while the actual GL context and Wayland resources remain alive.
   Eventfd readiness is not native-fence success, and `glFinish` is not bounded.
3. Separate ordinary parent-resource destruction from global shutdown; keep
   submitted child frames valid across parent destruction, but revoke their
   delivery when the frame itself is destroyed.
4. Quiesce producers, detach stop/erase callbacks, retain unique session owners
   through stop, and keep the lazy manager inert through dependency teardown.
5. Propagate failed cleanup through both normal main and destructor fallback,
   without unwinding unresolved GPU owners. Packaged launcher status preservation
   is separate from the private harness's direct-child result.

Preserve existing plugin incoming-argument ownership and reverse-unhook fixes.
Compositor launches remain disabled during this implementation stage.

## Upstream material

The patch context is derived from Hyprland's BSD-3-Clause-licensed source.
`LICENSE.upstream` preserves its copyright and terms. Applied base-file hashes
are recorded in the verification receipt; a directory name alone is not revision
proof.
