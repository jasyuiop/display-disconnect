import SwiftUI

@main
struct DisplayDisconnectApp: App {
  // `@State` değil: Command Line Tools'ta SwiftUIMacros plugin'i yok. @Observable model bir `let`
  // olarak tutulur; SwiftUI okumalarını yine izler.
  private let model = DisplaysModel()

  var body: some Scene {
    MenuBarExtra("Display Disconnect", systemImage: "display") {
      MenuContent(model: model)
    }
    .menuBarExtraStyle(.window)
  }
}
