# STYLE.md — Coding & Project Organization Rules

> The two governing rules for this repository. Every change defers to this file.
>
> Scope: all macOS source files in the repo (Swift + Obj-C + C++). The repo is
> macOS-only as of 2026-09-08; the iOS demo targets were migrated out and live
> in a separate archive (`iOS-demo-projects-backup-2026-09-08.zip` at the repo
> root until removed).

---

## Rule 0 — Language (meta-rule)

> Everything that ends up in git must be **English**. The maintainer's day-to-day
> dialog with their AI assistant (including memory, scratch notes, and rules
> during conversation) can stay in any language that is productive for them.

### What ships in English

| Surface | Language | Example |
| --- | --- | --- |
| Source code (`.swift`, `.m`, `.h`, `.mm`, `.cpp`, `.hpp`) | English identifiers, English comments | `/// Starts a non-blocking conversion.` |
| Customer-facing docs (`README.md`, in-source docs, release notes) | English | `README.md` is already English — keep it that way. |
| This `STYLE.md` itself | English (it ships in git) | — |
| Git commit messages, branch names, PR titles | English | `feat(s1b): adopt WKWebView preview` |
| Xcode navigator labels, Info.plist strings | English (`CFBundleDisplayName`, etc.) | — |
| Localized `.strings` (when added) | Match the target locale | `en.lproj/Localizable.strings` |

### What stays local (not in git)

| Surface | Language | Notes |
| --- | --- | --- |
| AI conversation with the maintainer | Maintainer's choice | Often Chinese or English, whatever is fastest. |
| AI assistant state files (see enumeration below) | Maintainer's choice | Tool-specific; never in git. Regenerable from the conversation or the tool itself. |
| Workspace bootstrap files (`SOUL.md`, `IDENTITY.md`, `USER.md`, `BOOTSTRAP.md` at `~/.workbuddy/`) | Maintainer's choice | Outside the repo, never in git. |

### AI assistant state files

The following files / directories are produced by popular AI coding assistants
and IDE integrations. They are **per-machine, per-session state** and must
**never** be committed. `.gitignore` mirrors this list.

| Tool | State path(s) / file(s) |
| --- | --- |
| WorkBuddy | `.workbuddy/`, `SOUL.md`, `IDENTITY.md`, `USER.md`, `BOOTSTRAP.md` (the last four live at `~/.workbuddy/`, but the project-side `.workbuddy/` covers the per-project daily logs and `MEMORY.md`) |
| Claude Code | `.claude/`, `CLAUDE.md`, `.claude.json` |
| Cursor | `.cursor/`, `.cursorrules` |
| Aider | `.aider*`, `.aider.chat.history*`, `aider*` |
| Continue | `.continue/`, `.continuerules` |
| GitHub Copilot | `.github/copilot-instructions.md`, `.github/copilot/` |
| Cody (Sourcegraph) | `.cody/`, `.cody.json` |
| Windsurf | `.windsurf/`, `.windsurfrules` |
| Cline | `.clinerules/`, `.cline/` |
| Roo Code | `.roo/` |
| Gemini CLI | `GEMINI.md`, `.gemini/` |
| Codeium | `.codeium/`, `.codeiumignore` |
| Tabnine | `.tabnine/`, `.tabnine_root/` |
| Zed AI | `.rules`, `AGENTS.md` (project-level only; the global `AGENTS.md` lives in `~/.config/zed/`) |
| Generic cross-tool convention | `AGENTS.md`, `CLAUDE.md`, `.cursorrules` (treat as local even if some tools allow project-level — prefer per-machine config) |

**Operational rules:**

1. None of the above ever appear in `git ls-files` or as tracked content. If
   you find one in a `git add`, remove it from the index immediately.
2. The whole enumeration is mirrored in `.gitignore` under a single
   `## AI assistant state (per-machine, never in git)` block. When you adopt
   a new tool, add its state path there in the same PR that documents it
   here.
3. AI assistants that are pointed at this repo must read `STYLE.md` and
   respect this rule before generating or committing anything.
4. Customer-facing `README.md` does not mention any of these tools or paths;
   they are purely maintainer-side concerns.

### Enforcement

The maintainer audits pre-commit / pre-PR manually. Future improvement (not required today):
add a CI check that fails if a non-ASCII char appears in any `.swift / .m / .h / .mm`
comment or in any top-level `.md` file outside of an explicitly-localized `.lproj`.

---

## Rule 1 — Code Formatting

> No auto-formatting tools (no `swift-format` / `clang-format` / `SwiftLint`).
> Every developer enforces the rules below by hand.

### Common (Swift + Obj-C)

| Item | Convention |
| --- | --- |
| Indentation | **4 spaces**, tabs disabled |
| Line ending | LF (`\n`), no CRLF |
| File trailer | Exactly one blank line at end of file |
| Line width | Soft cap **120 chars**; wrap when meaningful, never hard-wrap a single expression into unreadable form |
| Trailing whitespace | Strip on every line |
| Encoding | UTF-8 (no BOM) |
| Import order | System frameworks → third-party → project; alphabetical inside each group; one blank line between groups |
| File header comment | Must include: project name, Spec id (`S1 / S1b / S2 / …`), key version milestones (`v*` notes), Copyright (Flyingbee Software, 2026) |
| `#pragma mark` / `// MARK:` | Every `.m` / `.swift` has at least one section; group related members; section order: lifecycle → public API → private helpers |
| Lines per file | Soft cap **600 lines** (no hard rule; cell / view readability wins) |

### Swift

| Item | Convention |
| --- | --- |
| Naming | `UpperCamelCase` for types / protocols / enum cases; `lowerCamelCase` for variables / functions / properties; module-level constants use `UpperCamelCase` (e.g. `AppInfo.productName`) |
| Type prefix | None; module name is the disambiguator |
| Access control | Default `internal`; mark `public` only at API boundaries; single-file helpers are `private` / `fileprivate` |
| Optionals | Prefer `guard let` / `if let` early-exit; avoid `!` force-unwraps unless invariant has been asserted |
| Closures | Single-line may omit `return`; multi-line use trailing closure; `$0`/`$1` only when self-evident |
| Strings | Display text uses `"…"`; when text contains `'` or complex escapes, use `#""#` raw strings |
| Comments | `///` doc comments on public / non-obvious API; `//` for inline notes; delete commented-out dead code |
| `print` | Debug logging goes through `NSLog("[Tag] %@", …)` or `os_log`; no leftover `print` in release |
| Switch | Cases always end with explicit `break` / `return`; no implicit fallthrough |

### Obj-C / C++

| Item | Convention |
| --- | --- |
| Naming | `UpperCamelCase` for classes / protocols / enums; `lowerCamelCase` for methods / variables; constants use `UPPER_SNAKE` |
| Class prefix | **Every** custom class uses the `FP` prefix (`FPColors`, `FPSampleTableViewCell`, …) |
| Headers | Public API lives in `.h`; internals use class extension / class-continuation or `FP+Internal.h`; never expose implementation details in `.h` |
| `NS_ASSUME_NONNULL_BEGIN/END` | Every public `.h` must wrap its declarations |
| Properties | Scalars use `assign` / `copy`; objects default to `strong`; delegates and blocks with back-reference are `weak`; IBOutlet is `weak`; expose `readonly` publicly and mutate via private setter |
| Initialization | `init` returns `instancetype`; failing initializers return `nil`; multi-stage init separated by `// v*: …` notes |
| Literals | `@"…"`, `@42`, `@[@1, @2]`, `@{@"k": @"v"}`, `@(3.14)`; never `[[NSArray alloc] initWithObjects:… nil]` |
| `BOOL` | Use `YES` / `NO`; never `true` / `false` or `1` / `0` |
| `nil` checks | `if (obj)` / `if (!obj)`; never `if (obj != nil)` (redundant) |
| Switch | Explicit `break`; `default:` required unless there is exactly one case |
| C++ bridging | Use `.mm`; wrap C interfaces in `extern "C"`; do not put C++ templates in `.h` |

---

## Rule 2 — Xcode Project File Organization

> Every Xcode target organizes its files into **layers-by-responsibility
> Groups** in the navigator. Each Group is **alphabetized**. The disk layout
> is left untouched (Xcode Groups are virtual folders).

### Group layout

Every macOS app target uses the following fixed-order group layout:

| Group | Contents | Naming convention |
| --- | --- | --- |
| **App** | App entry (`main.m` / `AppDelegate.*` / `*App.swift`) | `App*` / `AppDelegate` |
| **Models** | Data models / app info / constants | `<Domain>Info` / `<Domain>Model` |
| **Views** | View controllers (VC), `UIView` / SwiftUI views, custom cells, previewers | `*View` / `*ViewController` / `*Cell` / `*Preview` |
| **ViewModels** | State machines / business logic (`ConverterViewModel` / `ConverterController`) | `*ViewModel` / `*Controller` (business class, not view class) |
| **Helpers** | Colors, extensions, utility functions, pure helpers | `FP*` / `*Helper` / `*Util` |
| **Bridging** | Swift ↔ Obj-C bridges (`*.h/.mm` bridge files, bridging header) | `*Bridge*` / `*-Bridging-Header.h` |
| **Resources** | `Info.plist`, LaunchScreen / storyboards, asset catalogs, sample bundle (disk still lives in `Supporting Files/` to keep `INFOPLIST_FILE` happy) | — |
| **Frameworks** | Embedded `.xcframework` / `.framework` | — |
| **Products** | The built `.app` | — |

### Sorting rules

- Each group is **strictly alphabetically sorted** (case-insensitive; `FP*` prefixes sort by their full name).
- `.h` files come before `.m` / `.mm` files when both sit in the same group (typical for Bridging).
- Groups themselves follow the table order above (App → Models → Views → ViewModels → Helpers → Bridging → Resources → Frameworks → Products).

### Group name vs. group path

- Group **`name`** (display label) follows the table above (e.g. `Resources`).
- Group **`path`** (disk path) stays minimal:
  - `App/Models/Views/ViewModels/Helpers/Bridging` are **virtual groups**: `name = "Views"` and no `path`.
  - `Resources`: `name = "Resources"` and `path = "Supporting Files"` (kept for `INFOPLIST_FILE`).
  - `Frameworks`: `name = "Frameworks"`, no `path` (the `.xcframework` itself uses a relative path).
  - `Products`: `name = "Products"`, no `path`.

### Adding a new file

1. Pick the correct group per the table.
2. Default physical location is the target's source root (do not create new subfolders casually).
3. Insert the file reference in its alphabetical slot within the group.
4. Re-sort the group in Xcode after the change so the diff stays minimal (see below).

### `project.pbxproj` maintenance

> Historical note: the iOS demo targets (S1b / S2) were maintained via Python
> generators and were removed from this repo on 2026-09-08 (the project is now
> macOS-only; the iOS sources live in a separate archive).

The two macOS targets maintain their `project.pbxproj` by hand in Xcode, but
the group layout and sorting rules above still apply **by convention**:

- Keep groups in the fixed table order and alphabetized, as if generated.
- After add / delete / rename of a source file, verify the navigator still
  matches the rules above before committing.
- `git diff` on `project.pbxproj` should stay minimal — never reorder noise.

### Relationship between filesystem and Xcode groups

- Filesystem does **not** have to mirror groups 1:1. Groups are logical; the
  disk keeps its current flat layout to avoid breaking `INFOPLIST_FILE` and `#import` paths.
- The single exception: the `Resources` group's `path` must stay
  `Supporting Files`, because `INFOPLIST_FILE` references
  `"<target>/Supporting Files/Info.plist"` on disk.
