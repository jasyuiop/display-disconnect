import DisplayBackendCG
import DisplayCore
import DisplayStorage
import Foundation
import Observation

@MainActor @Observable
final class DisplaysModel {
  private(set) var rows: [DisplayRow] = []
  private(set) var errorMessage: String?

  private let service = DisconnectService(
    backend: CGDisplayBackend(),
    store: FileStateStore(url: FileStateStore.defaultURL))

  func refresh() {
    do {
      rows = DisplayMenuPresenter.rows(try service.list())
      errorMessage = nil
    } catch {
      rows = []
      errorMessage = (error as? LocalizedError)?.errorDescription ?? String(describing: error)
    }
  }
}
