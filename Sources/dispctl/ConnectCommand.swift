import ArgumentParser

struct ConnectCommand: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "connect",
    abstract: "Reconnect a disconnected display and restore its layout."
  )

  @Argument(help: "ID of a display shown as `disconnected` by `dispctl list`.")
  var id: UInt32

  func run() throws {
    try reportingErrors {
      let result = try makeService().connect(id)
      if result.alreadyConnected {
        print("Display \(id) was already connected; the stale record was cleared.")
        return
      }
      print("Display \(id) reconnected.")
      if result.originRestored {
        print("Its position was corrected to match the recorded layout.")
      }
      if result.sizeDiffers {
        print("Warning: its size differs from the record and was left unchanged.")
        print("See `dispctl list`.")
      }
    }
  }
}
