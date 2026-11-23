# `agent_browser` failure audit

## Scope and result

I audited the seven Pi chats already saved for `/home/zhenya/ukraine-trade-lecture` when this investigation began. Four used native `agent_browser`: **124 calls, 14 explicit errors**. The count comes from Pi's `toolResult.isError`, not error keywords in prose. Two additional calls returned success while reporting the wrong page, and two successful-looking tests did not prove what they were meant to test. Live diagnostic calls in this audit are not in the historical totals.

I reproduced the two important failures without Quarto or Reveal: a fresh button ref became unusable and the only tab became `about:blank`; a mouse move hit an iframe but the subsequent wheel event went to the parent at `(0, 0)`. I also reproduced offline emulation disappearing after a new `open`. None of those reproductions required a remote site, a profile, a project edit, or a direct shell call to `agent-browser`.

## Every explicit failure

The numbers in the middle column are physical JSONL lines under `~/.pi/agent/sessions/--home-zhenya-ukraine-trade-lecture--/`. The UTC timestamp in the first column identifies the file by its prefix, not necessarily the time the command ran.

| Chat file prefix | Call → result | What failed and what followed |
|---|---:|---|
| `2026-11-20T16-39-54` • full-screen deck QA, 1/30 | 84 → 85 | `viewport 1920 1080` was not a command. `set viewport 1920 1080` immediately worked at 86–87. |
| `2026-11-21T17-39-08` • first timeline, 2/40 | 89 → 90 | `click @e7` returned `Unknown ref` immediately after snapshot 88 listed that exact focusable timeline region. No intervening page mutation was logged. |
| Same | 91 → 92 | The fallback evaluated `.focus()` on a null `#timeline-scroll`. The selector existed after reopening the same timeline route at 99–104. Wrong-page execution fits the later confirmed pattern; this particular failure did not capture the live URL, so it remains an inference. |
| `2026-11-22T10-32-57` • Closeread, 8/40 | 148 → 149 | `click @e17` returned `Unknown ref`. Snapshot 143 had listed it in the iframe; a screenshot and console read intervened. This case alone would not rule out an ordinary stale ref. |
| Same | 150 → 151 | `scroll … --selector .history-frame` returned `Element not found`. The subsequent `reload` was nominally successful at 157 but reported `about:blank`. Scrolling the iframe element would not by itself verify scrolling its document. |
| Same | 170 → 171 | `click @e7` on **Expand timeline** failed directly after snapshot 169 showed the button. This was already a fresh managed session. |
| Same | 172 → 173 | Role/name click on **Expand timeline** also failed. `tab list` at 175 showed only `t1` at `about:blank`, with `restartedBackground: true`. |
| Same | 196 → 197 | `click @e7` failed again right after snapshot 195, this time over loopback HTTP rather than `file://`. The job at 198–199 opened the same URL and clicked the same button. Its new snapshot showed **Close expanded timeline**, and the screenshot was saved. |
| Same | 200 → 201 | `help set` returned `Unknown command: help`. Use `--help` or the installed command reference. |
| Same | 227 → 228 | The upstream 25 s wait for `cr-belovezha` expired after `mouse wheel 680`. Seven of eight batch steps reported success, including a screenshot. The final state still showed `cr-independence`, so the image did not verify the transition. |
| Same | 239 → 240 | The wrapper killed a nine-step frame/click/keyboard/screenshot batch at its 35 s watchdog. Exit 124, no JSON/stdout/stderr, no live URL recovered, zero confirmed steps, and no Maidan screenshot. The proposed retry at step 1 was the first *unconfirmed* step, not proof that `open` hung. |
| `2026-11-22T10-37-06` • dark mode / font, 3/14 | 40 → 41 | `click @e1` failed immediately after snapshot 39 showed **Toggle dark mode** at `@e1`. |
| Same | 42 → 43 | The role/name fallback also failed. The next snapshot at 45 returned success but showed `about:blank`, zero refs, and `restartedBackground: true`. The one-job retry at 46–47 clicked the toggle and showed **Toggle light mode** in the resulting snapshot. |
| Same | 72 → 73 | Raw `batch` received an array of objects. The CLI expects arrays of argv strings, such as `[["open", "URL"], ["snapshot", "-i"]]`. Correcting the shape worked at 74–75. |

## What went wrong

### 1. The page was lost, not merely the ref

Several old snapshots contained the exact target in the same named session, then `click` failed without an intervening navigation or re-render. The wrong-page cases spanned a focusable region, an Expand button, and a separate dark-mode worktree. The Expand failure happened on both `file://` and HTTP. The failed calls sometimes still carried `details.sessionTabTarget` and `details.refSnapshot` for the deck. Those are saved wrapper state, not a live URL check. The actual tab list and fresh snapshot are stronger evidence.

The live control used a `data:` page with one button that changes its label from `Before` to `After` on click. Separately issued `open` → `snapshot -i` produced `@e1`; the next `click @e1` failed and `tab list` showed only `about:blank`. A separate run using a top-level role/name click failed similarly. On the same fixture, a one-call `job` with open, readiness, role click, and `assertText: "After"` passed; a raw `batch --bail` with open, snapshot, ref click, and a bounded wait also passed. A separate top-level CSS click worked in a control run. This is not a general inability to click, nor a missing deck control.

What remains unknown is the exact trigger for the page loss. Some follow-up results reported the upstream background had restarted; others reported it was reused. The wrapper's managed-session name staying the same does not imply that the browser page or background process survived. The installed wrapper has best-effort tab recovery, but it cannot reselect a page missing from the tab list. I did not capture an upstream daemon crash trace or isolate wrapper code from the upstream CLI, so I would not assign this to either component yet. The current native `--version` reports upstream **0.31.1**; the installed wrapper is **0.2.67**, whose changelog says it was validated against **0.31.2**. That makes a version-matched rerun worthwhile; it does not make version skew an established cause or an upgrade a verified fix.

### 2. The wheel input went to the wrong place

In the Closeread chat, `elementFromPoint` placed the pointer over the iframe. Instrumentation at 229–230 and 235–236 then recorded an inner `mousemove` but a parent `wheel` at `(0, 0)`, with iframe `scrollY` still `0`. The `scrolled: true` response meant that the command returned success, not that the target scrolled. Waiting for a different active photo could not repair that.

I reproduced this in a plain `srcdoc` iframe at `(100, 100)`, with a 3,000 px-tall child. After `mouse move 250 250`, the frame received `mousemove` at `(148, 148)`. `mouse wheel 500` sent a parent wheel event at `(0, 0)`; the frame still read `scrollY: 0`. This rules out the deck's layout and Closeread as necessary causes. The historical direct `scrollTo` checks do show that programmatic scrolling changes the active steps; they are not native wheel coverage.

### 3. Two distinct timeouts and an unverified offline claim

- **25 s upstream condition wait:** A real postcondition failed. Keep that assertion, shorten its timeout, and capture live scroll position, event target, and active step on failure. Do not raise the timeout to compensate for wheel events going to the parent.
- **35 s subprocess watchdog:** There was no final batch response, so no evidence identifies the hanging row. Split the frame test into a readiness/frame check and a short interaction with explicit step timeouts. Confirm live state before retrying any click that might already have run.
- **Offline run:** The earlier copied-deck test at 216–217 recorded `allScrollTransitions: true`, `images: true`, and synthetic keyboard success, but also recorded `offline: false` from `!navigator.onLine`. It verified a standalone-file workflow, not offline emulation. In a live control, `set offline on` flipped `navigator.onLine` to `false` on page A, opening page B put it back to `true`, and reapplying the setting flipped it to `false` again. An actual cold-start offline test should block networking before navigation in a way that persists and verify the block with a known network request. The old readiness expression `iframe?.contentDocument?.querySelector(...) !== null` was also too weak: it evaluates true when the chain returns `undefined`. Wait for a positive element or active-step ID instead.

### 4. One separate deck behavior

The older scrollable timeline had an actual keyboard issue. In `2026-11-21T17-39-08…`, lines 100–108 and 118–125 show a working deck, then `ArrowDown` or `PageDown` successfully dispatched, then Reveal advancing to `#/output` with timeline `scrollTop: 0`. Later the chat confirmed that the region could hold focus. This is consistent with Reveal taking the keys, not a failed native `press`. The chat eventually removed the misleading keyboard instruction and explicitly recorded the unresolved accessibility issue at line 219. It predates the Closeread rewrite; it does not prove a defect in the current deck.

## Practical fixes

1. For this deck's UI QA, use `job` with `open` → readiness → exact role/name click → explicit postcondition. For refs, use `batch --bail` with the snapshot and action in the same call. A screenshot comes after the assertion, or it should be named and reported as failure evidence.
2. After a stale ref, check `tab list` or the live URL before guessing locators or changing deck CSS/JS. Reselect only if the intended tab exists. If the tab list contains only `about:blank`, reopen in the same call as the check or action. A fresh session on its own did not prevent recurrence.
3. Use programmatic frame scrolling to test Closeread's state transitions. Treat real wheel input as a separate regression test that proves event delivery and nonzero child `scrollY`. Do the same for real keyboard focus and input, rather than counting `dispatchEvent` as hardware-equivalent coverage.
4. File separate issues for page loss and wheel coordinates if they persist on the matching upstream version. Attach the tiny fixtures, exact argv, lifecycle flags, and postconditions. The watchdog alone does not yet identify a third reproducible tool defect.

## Follow-up: tested mitigation and upstream fix criteria

I temporarily ran the installed wrapper against upstream 0.31.2, its documented validation baseline. Both original failures reproduced: separate snapshot/ref-click left only `about:blank`, and wheel input still reached the parent at `(0, 0)`. Direct iframe scrolling moved the fixture to `scrollY: 500`. I restored the original 0.31.1 binary because the upgrade did not fix either issue.

The native browser and project visual-QA skills now prefer fail-fast, single-call checks. The [timeline smoke test](../.pi/skills/visual-qa/references/timeline-smoke.md) passed on the restored install: actual iframe fullscreen, visible Close control, then `cr-belovezha` active with child scroll `0 → 492` and Reveal still on `timeline`. The screenshot was produced after those assertions. This verifies the workaround, not the native wheel path.

For a code fix, run the split-call fixture on the standalone upstream CLI and through the Pi wrapper under the same log settings. If it fails only through Pi, trace the wrapper's preflight and click-probe subprocesses; if both fail, trace the upstream daemon/session lifecycle. A fix must preserve the tab and current ref across separate calls, including after a harmless read. For wheel, inspect which coordinates upstream sends to Chromium after `mouse move`; add a regression fixture that requires the trusted wheel event to reach the iframe and change child `scrollY`. A successful command response without those postconditions should not pass either test.

## Evidence and reproduction

- Audit session: `2026-11-22T10-55-32-463Z_01a202e5-9e6e-755a-8a0a-579c072732fb.jsonl` in the same Pi session directory. The first lost-page reproducer and both successful single-call controls are at lines 36–47. The failed role/name control is at 55–62; the working separate CSS click is at 75–84.
- Current wheel and offline control JSON: `.pi-agent-browser-artifacts/01a202e5-9e6e-755a-8a0a-579c072732fb/pi-agent-browser-output-b6734b085414c61f.json` and `pi-agent-browser-output-99330a047b8f3b80.json`, respectively, under the Pi session directory. Historical wheel evidence is in the Closeread chat at lines 228, 230, and 236, including per-step results.
- Minimal lost-page fixture: `data:text/html,%3Ctitle%3EAB%20Probe%3C%2Ftitle%3E%3Cbutton%20onclick%3D%22this.textContent%3D%27After%27%22%3EBefore%3C%2Fbutton%3E`. Open in a fresh native session, snapshot, click the displayed ref in a separate call, then list tabs. As a control, put open, readiness, click by role/name, and `assertText: "After"` in a single job.
- Installed package documents: `~/.pi/agent/npm/node_modules/pi-agent-browser-native/CHANGELOG.md`, `docs/TOOL_CONTRACT.md`, and `docs/COMMAND_REFERENCE.md`. The `0.2.65` entry describes tab recovery; `0.2.67` records the validation baseline. Those documents explain intent, not what the failed process actually did.
