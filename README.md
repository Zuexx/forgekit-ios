# forgekit-ios

An iOS starter kit that carries the ForgeKit AI development workflow. Swift 6, SwiftUI, and a
Tuist-generated Xcode project — plus OpenSpec, CodeGraph, and the pre-push coverage hook that
the rest of the ForgeKit family runs.

## Setup

```bash
git clone https://github.com/Zuexx/forgekit-ios.git
cd forgekit-ios
pnpm install
git config core.hooksPath .githooks
pnpm exec codegraph init
pnpm preflight          # exits non-zero until the workflow genuinely works
pnpm verify             # generate, build, test
```

Requires Xcode and Tuist (`brew install tuist`). `pnpm preflight` names anything missing.

## Generating a product

Fork, then change the two lines at the top of `Project.swift`:

```swift
let appName = "YourApp"
let bundleIdPrefix = "com.yourcompany"
```

Then `pnpm verify`. The Xcode project is generated from that manifest, so those two lines are
the entire rename — there is no `.pbxproj` in the repository to edit.

Keep pulling base improvements afterwards:

```bash
git remote add upstream https://github.com/Zuexx/forgekit-ios.git
git fetch upstream && git merge upstream/main
```

## Layout

```
Project.swift              the source of truth for the Xcode project
Sources/App/               @main entry point
Sources/Samples/           the one sample feature: model, service protocol, view
Tests/                     Swift Testing unit tests
scripts/verify.sh          the acceptance gate, and what CI runs
scripts/preflight.sh       shared; reports whether the workflow is operational
scripts/sync-workflow.sh   shared; pulls workflow updates from forgekit-workflow
openspec/                  specifications, and the rules that shape them
AGENTS.md                  instructions for agents working in this repository
```

`ForgeKit.xcodeproj` and `ForgeKit.xcworkspace` are generated and gitignored. Never edit them
by hand; `tuist generate` overwrites them.

## The sample feature

`SampleListView` renders whatever a `SampleResourceProviding` returns, through an
`@MainActor @Observable` model whose state is an explicit enum. It exists to prove the chain
from service to model to view is wired and tested — replace it with a real domain rather than
building around it.

## The workflow

`AGENTS.md` is the entry point. In short: `/opsx:propose` to plan a change, `/opsx:apply` to
implement it, `codegraph_explore` instead of reading files to find what a change affects, and
`pnpm verify` before calling anything done.

Shared workflow files come from
[forgekit-workflow](https://github.com/Zuexx/forgekit-workflow) and are updated with
`pnpm sync-workflow`. Edit them there, not here.
