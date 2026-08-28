import Foundation
import Observation

@Observable
@MainActor
final class ShareModel {
  enum State {
    case saving
    case saved(Link)
    case failed(String)
  }

  var state: State = .saving
}
