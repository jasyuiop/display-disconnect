import SwiftUI

@main
struct DisplayDisconnectApp: App {
  // Not `@State`: the Command Line Tools ship no SwiftUIMacros plugin. The @Observable model is
  // kept as a plain `let`; SwiftUI still tracks the reads.
  private let model = DisplaysModel()

  var body: some Scene {
    MenuBarExtra("Display Disconnect", systemImage: "display") {
      MenuContent(model: model)
    }
    .menuBarExtraStyle(.window)
  }
}
