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

- `SubmittedWork.hpp`: renderer-owned payloads independent of scoped readable
  registrations. Cancelling delivery or closing the event registry leaves source,
  destination and render-target ownership in the queue. Native sync-file status
  is checked with `SYNC_IOC_FILE_INFO`; readiness alone is not success. Errors and
  failed registration retain their payload without delivering success. Drain
  passes one absolute deadline to every wait, retains ownership on timeout/error,
  and refuses unresolved-owner destruction.
- `renderer-retirement.patch`: moves explicit-sync submissions into that queue,
  with non-release-point source locks, a separate copy-destination lock/storage,
  renderbuffer and current/main/output framebuffer references captured before GL
  end resets them. Existing explicit source release-point import and ordinary
  output in-fence paths remain in place. Failed fence creation retains all source
  locks and destination resources instead of reporting a successful copy. The
  new renderer drain checks EGL binding, actual current display/context and reset
  status before retiring records. An early renderer destructor guard prevents
  member teardown with unresolved submissions.

These changes do **not** yet make parent-session destruction preserve outstanding
child-frame native state. The explicit-sync queue/drain is implemented, but its
compositor cleanup call and dependency ordering are not wired yet. Unsupported
explicit-sync and full-fake render branches remain unchanged; the implicit
`glFinish`/`glFlush` path is not bounded shutdown acceptance. Additional transient
resources and explicit framebuffer releases still need lifecycle integration.

## Verify without starting a compositor

Set `CHECKOUT` to this checkout and `HYPRLAND_SOURCE` to the matching configured
Hyprland source tree with `build/compile_commands.json`, then run:

```sh
python3 "$CHECKOUT/tests/native-fit/build-core.py" --source "$HYPRLAND_SOURCE"
python3 "$CHECKOUT/tests/native-fit/verify-core-controls.py"
python3 "$CHECKOUT/tests/native-fit/verify-retirement-controls.py"
```

The first command compiles and executes the real C++ primitives under ASan/UBSan,
using libwayland-server event loops, eventfd and pipes. It then creates a private
source overlay, applies the combined patch with `git apply --check`, and runs the
actual configured compiler's syntax checks for `EventLoopManager.cpp`,
`ImageCopyCapture.cpp`, `ScreenshareFrame.cpp` and `GLRenderer.cpp`. The eight patched input
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

Latest focused execution: 13 submitted-work cases passed under ASan/UBSan and
both new retirement RED controls rejected their specific defects (cancellation
releases GPU owners; ioctl failure treated as success). All four actual compositor
translation units passed syntax checks; eight original files were hash-unchanged.
Tests use real Wayland event loops and eventfd for scheduling with injected fence
status, plus actual kernel rejection of eventfd/invalid FD as a sync_file. They do
not create GPU fences or execute EGL/GL. Earlier 14 waiter and 8 terminal cases
and their two RED controls were not rerun unchanged. Use `--test
test-submitted-work` on build-core for the focused run. No full compositor link
or runtime acceptance is claimed.

## Continue implementation

1. Wire the implemented renderer drain into compositor cleanup after producer
   quiescence, before any dependent GL/Wayland teardown; retain failed owners and
   propagate the failure without member unwinding. Cover unsupported explicit-sync
   submissions, full-fake/transient render resources and explicit FB release paths.
2. Preserve one absolute shutdown deadline and checked native fence status while
   integrating cleanup. The current checked EGL drain is syntax-checked, not
   executed. `glFinish` is not bounded.
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
