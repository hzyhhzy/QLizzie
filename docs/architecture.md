# Architecture and regression checks

QLizzie uses C++ for process and file access, QML for interaction and reactive
state, and JavaScript for deterministic transformations. `Main.qml` assembles
these parts, connects their effects and maintains presentation/configuration
properties used by the existing views.

## State ownership

| Owner | Owns | Public operations |
| --- | --- | --- |
| `GameSession.qml` | Game tree, current node, board position, captures, ko, player and generation | Move/pass, navigate, delete/promote, load, update analysis annotations |
| `EngineSession.qml` | Sync snapshots, analysis/genmove/AI requests and their timers | Begin, stage/commit sync, accept/complete a request, cancel/invalidate, shutdown |
| `AnalysisSession.qml` | Candidate and ownership display, projected marker/table data, cache policy | Apply live updates, restore caches, rebuild presentation, reset |
| `Main.qml` | Settings values, window/dialog state, input selection and user-visible effects | Connect session signals to rendering, engine commands, status and dialogs |
| `EngineController` | QProcess, GTP queue, stream buffering and bounded communication log | Start/stop, send commands, emit parsed results and protocol completions |

The session components do not accept the application object. Their inputs are
explicit values, small callbacks or operation arguments. Main's game/request/
analysis properties are read-only mirrors for existing view consumers. A new
consumer should read the relevant session and invoke its operations rather than
write those mirrors or mutate a node returned by `nodeById`.

`GameTree.js` implements transitions without modifying their input snapshots.
`GameSession.commit` publishes a successful result before emitting tree and
position signals. Rejected operations preserve the old state. Tree edits and
position changes are distinct, so adding analysis annotations does not trigger
an engine resynchronization. `updateNodeAnalysis` is the narrow write interface
for metadata; callers must reacquire nodes after replacement.

`GameRules.js` remains the rule engine. Source/target games use its move
transitions both for actual play and `MovePreview.js` previews. This keeps
captures, source selection and turn changes consistent across both paths.
`TreeLayout.build` projects nodes into view geometry using an iterative traversal
and has no access to window state.

## Engine and analysis lifecycle

Every engine operation captures the node ID, game generation, board signature,
komi/parameter signature and engine identity. A monotonic request ID identifies
the operation. EngineSession validates that identity before committing sync or
accepting a completion; a response for an earlier operation cannot cancel a
newer request. Switching games/engines and shutting down invalidate the relevant
requests and timers. UI-throttled candidate updates retain the sync token and
check it again when flushed.

`EngineSync.js` computes incremental command plans. EngineSession owns the staged
and committed snapshots. Main sends the resulting commands through the C++
controller and applies accepted moves through GameSession. Source-only nodes in
two-part moves force a full synchronization before the next engine request.

`AnalysisCache.js` decides cache applicability and creates analysis annotations.
`CandidateModel.js` builds marker/table projections from entries and presentation
settings. AnalysisSession writes annotations through the supplied node writer,
without changing tree topology. Historical candidate caches preserve the
existing board-and-komi matching policy, including imported SGF analysis.
Historical ownership also requires the engine identity. Live updates always
require a current request. Imported caches are displayed after their missing
signatures have been finalized.

`EngineAnalysis::parseInfoLine` in `engineanalysis.cpp` converts a complete info
line into a batch of candidates and ownership using Qt value types. It has no
QObject or QProcess dependency. EngineController publishes nonempty candidate
batches; newline buffering, GTP failures and log limits remain in the controller.

## Settings and UI boundaries

`SettingsSchema.js` defines the ordered mapping, types and missing-value policy
for all 87 persisted keys. Its `read`, `write` and `snapshot` functions operate on
value objects. Startup defaults remain in Main. `SettingsStore.js` adapts those
values to QSettings and the existing normalizers, then applies version migrations
in the original order. Temporary ownership display state is not persisted.
`rules/RulePreferences.js` shares visibility and ordering normalization between
settings and live rule selection.

The application menu and rule-selection/common-rule popups take explicit inputs
and emit action signals. Older board, settings and engine-preset views still use
the Main facade; their existing contracts are retained. Rule settings, engine
preset orchestration and much of presentation configuration still reside in
Main and the corresponding adapters. Future edits should maintain the session
boundaries above, rather than introduce new cross-module state writes.

## Build and test

Configure with Qt 6.9 or newer, Qt Test, Node.js and a C++17 compiler. On Windows,
use a Qt installation that matches the selected MSVC toolchain:

```powershell
cmake -S . -B build/qlizzie -DCMAKE_PREFIX_PATH=C:/Qt/6.10.3/msvc2022_64
cmake --build build/qlizzie --config Release
ctest --test-dir build/qlizzie -C Release --output-on-failure
```

CMake registers 23 JavaScript suites, 7 QML runtime suites and the C++ core suite
when their respective tools are installed. Check `ctest -N` if a suite is
missing. The QML runner must come from the selected Qt 6 installation; a Qt 5
runner elsewhere on PATH cannot load this application.

Individual JavaScript files can also run directly, for example
`node tests/game_tree.test.js`. `tests/qmlJsLoader.js` resolves actual QML JS imports
inside a VM; tests can explicitly replace an import when isolation is needed.

On Windows, normal builds also update the existing installation in `C:/qlizzie`.
The copy list is exactly `QLizzie.exe` and `bin/qlizzie.exe`; settings, engines,
models, logs, Qt libraries and other files are untouched. The installed Qt
runtime must match the selected build (the current Release build uses Qt 6.10.3).
Changed executable targets also copy after linking. Close QLizzie before building
if its executable is locked. Set `-DQLIZZIE_LOCAL_DEPLOY_DIR=...` at configure time
to change the destination, or `-DQLIZZIE_LOCAL_DEPLOY_DIR=` to disable the copy.
This update does not use the clean-directory portable packaging target.

`tst_application_session.qml` instantiates the real Main and its components with
in-memory settings/file/controller context objects. It covers move/branch/delete,
SGF roundtrip and rejection, candidate/ownership restoration, partial AI moves,
sync commits, engine changes and late/repeated callbacks. Reference/type errors,
read-only writes, undefined assignments and binding loops fail the suite. These
tests avoid touching user settings or starting an external engine. The C++ suite
separately tests stream/protocol parsing and controller behavior.

When changing state transitions, test both the successful result and unchanged
state on rejection. When changing asynchronous operations, test a late response
after a new operation or position change. For UI wiring, execute a real QML
component rather than only checking for a source-code string.
