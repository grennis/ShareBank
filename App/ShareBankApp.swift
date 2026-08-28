import Dependencies
import SQLiteData
import SwiftUI

@main
struct ShareBankApp: App {
  init() {
    prepareDependencies {
      try! $0.bootstrapDatabase()
    }
  }

  var body: some Scene {
    WindowGroup {
      LinksView()
    }
  }
}
