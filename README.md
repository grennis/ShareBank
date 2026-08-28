# ShareBank

A place to stash links you want to come back to.

Share a link from any app on iOS, pick **ShareBank**, and it lands in a local database. The app icon
badge tells you how many links are still waiting. Open the app to see them, tap one to send it back
out through the share sheet, or swipe it away to archive it.

## Features

- Share extension that accepts web links from anywhere in iOS
- Links stored in SQLite, shared between the app and the extension through an App Group
- App icon badge showing the number of unread links
- Tap a link to re-share it via the system share sheet
- Swipe to archive; archived links live in their own view and can be unarchived or deleted
- Sharing the same URL twice refreshes the existing entry instead of duplicating it

## Requirements

- Xcode 26 or later (built and verified with Xcode 27), iOS 18.0+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

## Getting started

The Xcode project is generated from `project.yml` and is not checked in:

```bash
xcodegen generate
```

Then open `ShareBank.xcodeproj` and run the `ShareBank` scheme. You will need to change
`DEVELOPMENT_TEAM`, the bundle identifiers, and the App Group in `project.yml` to your own before
running on a device.

Run the tests with:

```bash
xcodebuild -project ShareBank.xcodeproj -scheme ShareBank -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
```

## How it works

The app and the share extension are separate processes that read and write one SQLite file in the
App Group container, so everything in `Shared/` is compiled into both. The extension pulls the URL
off the incoming `NSItemProvider`, writes a row, updates the badge, and dismisses.

```
Shared/     AppGroup, Schema (@Table Link + migrations), LinkStore, BadgeUpdater
App/        SwiftUI: LinksView, ArchiveView, LinkRow
ShareExtension/  ShareViewController + confirmation card
Tests/      LinkStoreTests
```

Built on the [Point-Free](https://www.pointfree.co) stack: **SQLiteData** for persistence and
observed queries, **SwiftUINavigation** and **CasePaths** for state-driven presentation,
**Sharing** for App Group preferences, and **Dependencies** for testable wiring.

See [AGENTS.md](AGENTS.md) for development notes and the sharp edges worth knowing about.
