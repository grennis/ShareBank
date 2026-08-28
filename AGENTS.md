# ShareBank — agent notes

iOS app + share extension. Links shared from the iOS share sheet are stored in SQLite; the app
icon badge counts the links still waiting to be read.

## Project layout

The Xcode project is **generated** — `project.yml` is the source of truth, and `ShareBank.xcodeproj`
is gitignored. After changing `project.yml`, adding files, or cloning:

```bash
xcodegen generate
```

| Path | Target(s) | Notes |
|---|---|---|
| `Shared/` | app **and** extension | Persistence and badge logic, compiled into both processes |
| `App/` | ShareBank | SwiftUI UI |
| `ShareExtension/` | ShareBankShareExtension | `ShareViewController` is the principal class |
| `Tests/` | ShareBankTests | Swift Testing, hosted by the app |
| `Tools/` | — | `swift Tools/GenerateAppIcon.swift` redraws the app icon PNGs |

Bundle IDs `com.innodroid.ShareBank` / `com.innodroid.ShareBank.ShareExtension`, App Group
`group.com.innodroid.ShareBank`, team `S8T7K4M873`, deployment target iOS 18.0.

## Build and test

Prefer the Xcode MCP tools (`XcodeOpenWorkspace` on `ShareBank.xcodeproj`, then `BuildProject` /
`RunAllTests`). The scheme is `ShareBank`; the simulator used for verification is iPhone 17 Pro.
Equivalent CLI:

```bash
xcodebuild -project ShareBank.xcodeproj -scheme ShareBank -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
```

New dependencies need `xcodebuild -resolvePackageDependencies` before the first build.

## Libraries

Point-Free stack. Load the matching `pfw-*` skill before working in these areas:

| Library | Used for | Skill |
|---|---|---|
| SQLiteData | `@Table Link`, migrations, `@FetchAll` | `pfw-sqlite-data` |
| StructuredQueries | query building (via SQLiteData) | `pfw-structured-queries` |
| SwiftUINavigation + CasePaths | `Destination` enum, `Binding($destination.case)` | `pfw-swift-navigation` |
| Sharing | App Group user-defaults flag | `pfw-sharing` |
| Dependencies | `@Dependency`, `prepareDependencies` | `pfw-dependencies` |

## Things that will bite you

**The database is shared by two processes.** `Shared/Schema.swift` points `defaultDatabase` at the
App Group container, but only when `@Dependency(\.context) == .live` — previews and tests stay
in memory, which is why `LinkStoreTests` never touches the real database.

**`@FetchAll` cannot see the extension's writes.** GRDB's observation is same-process only. Links
saved while the app is backgrounded only appear because `LinksView` re-runs its query on
`scenePhase == .active` (`$links.load(...)`). Any new observed query in the app needs the same
treatment, or the user will see stale data after sharing.

**The test target deliberately links no package products.** It picks up SQLiteData and Dependencies
through the host app. Linking them directly (or adding `DependenciesTestSupport`) promotes
`IssueReporting` to a dynamic framework, and both `xctest-dynamic-overlay` and
`swift-issue-reporting` vend a product with that name — the build then fails with
`Multiple commands produce ... IssueReporting...framework`. This is why the tests use a local
`withTestDatabase` helper instead of the `.dependencies` suite trait.

**Updates need `#bind`.** `Link.find(id).update { $0.archivedAt = now }` does not compile; it must be
`#bind(now)`, and clearing an optional is `#bind(Date?.none)`.

**The badge needs notification permission.** `BadgeUpdater` calls `setBadgeCount` from both
processes and falls back to a content-free `UNNotificationRequest` if that is rejected in the
extension. The `.badge` prompt is requested once, recorded in App Group defaults only *after* it is
answered so a dismissed prompt is retried.

**Only web URLs activate the extension.** `NSExtensionActivationSupportsWebURLWithMaxCount = 1` in
`project.yml`. Adding text or image support means changing that rule and the `UTType.url` extraction
in `ShareViewController`.

## Verifying on the simulator

Unit tests do not cover the share flow — it crosses process boundaries. To check it end to end,
share a page from Safari, confirm the badge increments, then open the app. Note that the reported
center of a `List` row is not always a live hit target; tap the row's title text instead.
