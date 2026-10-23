import DisplayBackendCG
import DisplayCore
import DisplayStorage
import Foundation
import Observation

@MainActor @Observable
final class DisplaysModel {
  private var state = MenuState()
  var rows: [DisplayRow] { state.rows }
  var errorMessage: String? { state.errorMessage }
  var busyID: UInt32? { state.busyID }

  private let service = DisconnectService(
    backend: CGDisplayBackend(),
    store: FileStateStore(url: FileStateStore.defaultURL))
  private var observer: DisplayChangeObserver?
  private var pendingRefresh: Task<Void, Never>?

  init() {
    observer = DisplayChangeObserver { [weak self] in
      Task { @MainActor in self?.scheduleRefresh() }
    }
  }

  func refresh() {
    do {
      state.listLoaded(try service.list())
    } catch {
      state.listFailed(Self.message(for: error))
    }
  }

  /// The user's "Refresh" button: also dismisses an action error they may have already seen.
  func reload() {
    state.dismissActionError()
    refresh()
  }

  func perform(_ action: RowAction, on id: UInt32) {
    guard state.beginAction(on: id) else { return }
    let service = service
    Task {
      // In the background: `connect` may wait several seconds for the display to come back.
      let failure = await Task.detached(priority: .userInitiated) { () -> String? in
        do {
          switch action {
          case .disconnect: try service.disconnect(id)
          case .connect: try service.connect(id)
          }
          return nil
        } catch {
          return Self.message(for: error)
        }
      }.value
      state.finishAction(failure: failure)
      refresh()
    }
  }

  /// The system reports display changes in bursts; a short delay collapses them into one refresh.
  private func scheduleRefresh() {
    pendingRefresh?.cancel()
    pendingRefresh = Task {
      try? await Task.sleep(for: .milliseconds(400))
      guard !Task.isCancelled else { return }
      refresh()
    }
  }

  nonisolated private static func message(for error: any Error) -> String {
    guard let localized = error as? any LocalizedError else { return String(describing: error) }
    return [localized.errorDescription, localized.recoverySuggestion]
      .compactMap { $0 }
      .joined(separator: "\n")
  }
}
