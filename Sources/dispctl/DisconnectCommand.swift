import ArgumentParser

struct DisconnectCommand: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "disconnect",
    abstract: "Cut the video signal of an external display (charging continues)."
  )

  @Argument(help: "Display ID from `dispctl list`.")
  var id: UInt32

  func run() throws {
    try reportingErrors {
      try makeService().disconnect(id)
      print("Display \(id) disconnected. To bring it back: dispctl connect \(id)")
    }
  }
}
