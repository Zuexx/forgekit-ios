# Agent Instructions

forgekit-ios is an iOS starter kit used as a development base. Products are generated from it
by forking and renaming, then diverge, so changes should stay reusable across products rather
than being tailored to the sample resource domain.

## Read before changing the project structure

The Xcode project is **generated**, not tracked. `Project.swift` is the source of truth;
`ForgeKit.xcodeproj` and `ForgeKit.xcworkspace` are gitignored and rebuilt by `tuist generate`.

Two consequences that are easy to get wrong:

- **Hand-editing the generated project is lost work.** Build settings, target membership, and
  scheme changes belong in `Project.swift`.
- **A new source directory has to be declared.** Targets take `sources: ["Sources/**"]`, so a
  file placed outside that tree compiles for nobody and fails silently at review time rather
  than at build time.

Renaming a product happens in exactly two lines — `appName` and `bundleIdPrefix` at the top of
`Project.swift`. That is the reason this repository uses a manifest instead of a checked-in
`.pbxproj`, where the same rename means editing dozens of internal references.

## Planning changes

Specifications live in `openspec/`. Project context, artifact rules, and per-operation guidance
are in `openspec/config.yaml`, and OpenSpec delivers them at the step they apply to — read what
it hands you rather than working from memory of this file.

`/opsx:explore` to think a change through, `/opsx:propose` to create one, `/opsx:apply` to
implement, `/opsx:archive` when it ships.

When a request is too vague for a proposal to state what it includes and excludes, run
`grillme` first — `pnpm exec grillme` from the repository root. It opens a browser, asks one
decision question at a time, and writes a Markdown handoff; it implements nothing. That handoff
is the input to `/opsx:propose`.

Write a change proposal for new capabilities, breaking changes, architecture shifts, and
security work. Skip it for bug fixes, typos, dependency bumps, and configuration changes.

### Two loops, and who owns which

OpenSpec decides **what may be built and whether it counts as done**. Superpowers decides
**how it gets built and whether it was built correctly**. Neither knows the other exists, so
the seam is the `apply` and `archive` guidance in `openspec/config.yaml`.

Feature-level tasks live in `openspec/changes/<slug>/tasks.md`. Minute-level steps live in the
Superpowers plan, which cites those task ids under `## OpenSpec Coverage`. Keep the two
granularities apart; collapsing them makes the citation meaningless.

### Overlapping skills, resolved by trigger

| Job | Use | Because |
|---|---|---|
| Clarify a vague request | `superpowers:brainstorming` | Fires on its own before creative work |
| Test-first implementation | `superpowers:test-driven-development` | The inner loop already speaks its vocabulary |
| Execute a plan | `superpowers:subagent-driven-development`, **if its decision tree sends you there** | It routes tightly coupled tasks to manual execution; a task and its own verification are not independent |
| Review a change | `superpowers:requesting-code-review` | Whichever route the work took, including small changes done inline |
| Review an arbitrary diff | `/code-review` | Ad-hoc, outside a change |

Reach for `codegraph_explore` before reading files to answer "what does this affect" — it
returns the callers and the test-coverage gaps that reading cannot, in one call. It indexes
symbols, so a contract addressed by string — a notification name, a `UserDefaults` key, a
URL path — is invisible to it and needs a literal search of its own.

## Building and testing

```bash
pnpm install         # the workflow toolchain: OpenSpec, CodeGraph, grillme
pnpm verify          # tuist generate, then xcodebuild test on a resolved simulator
```

`pnpm verify` is the acceptance gate and is what CI runs, so a green run locally means a green
run there. It resolves the newest installed iPhone simulator rather than naming one: a
hardcoded device is the line that breaks on the next machine for a reason unrelated to the code.

`.githooks/pre-push` checks that implementation plans cite OpenSpec task ids that actually
resolve — the one link between the two systems that nothing else validates. Enabling it takes
two steps, because git ignores a hook it cannot execute without reporting anything:

```bash
git config core.hooksPath .githooks
chmod +x .githooks/*
```

`pnpm preflight` reports whether this workflow is operational here at all — the declared tools
including `tuist` and `xcodebuild`, whether `openspec/config.yaml` still yields its rules
through the installed version, whether the CodeGraph index reflects current Swift source,
whether the hooks can fire, and whether every capability this file and `openspec/config.yaml`
name still resolves. Run it after cloning, and when something in the workflow behaves as
though a piece is missing. Each failure names its fix.

Invoke both through pnpm rather than as `./scripts/*.sh`, so that a copy which arrived without
the executable bit still runs.

## The shared workflow

`scripts/preflight.sh`, `scripts/sync-workflow.sh`, `.githooks/pre-push`, `.mcp.json`,
`.claude/settings.json`, and `openspec/rules.yaml` are owned by the forgekit-workflow
repository and shared with every ForgeKit-family repo. Edit them there, not here:

```bash
pnpm sync-workflow && pnpm preflight
```

overwrites them and re-splices the shared rules into `openspec/config.yaml` below the marker
line, so a local edit disappears without a word. What this repository owns is everything above
that marker — its `context:` block — plus `scripts/verify.sh`, `package.json`, and this file.

The stack half of preflight is declared, not hardcoded, in `package.json`:

```jsonc
"forgekit": {
  "sourceGlobs":   ["*.swift"],
  "requiredTools": ["tuist", "xcodebuild"]
}
```

## Conventions that are easy to get wrong

- **Views depend on a protocol, never a concrete service.** `SampleListView` takes a
  `SampleResourceProviding`. That indirection is what lets the model be tested without a
  network, a simulator, or a running app.
- **State is an enum, not a set of booleans.** `idle`, `loading`, `loaded`, `failed` are cases
  a test asserts directly; `isLoading` plus `error` plus `items` has states that cannot happen
  and tests that cannot say so.
- **Assert the value, not the absence.** A test that only checks nothing failed still passes
  when the model publishes an empty list.
- **Swift Testing, not XCTest.** `import Testing`, `@Test`, `#expect`.
- **Commits follow Conventional Commits.** Branch off main and open a PR so CI runs before
  merging.

## Where things are documented

| Topic | File |
|---|---|
| Setting up, and generating a product | `README.md` |
| Project generation and target layout | `Project.swift` |
