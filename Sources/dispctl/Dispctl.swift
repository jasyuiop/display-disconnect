import ArgumentParser
import DisplayCore

@main
struct Dispctl: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "dispctl",
    abstract: "Disconnect and reconnect the video signal of external displays.",
    version: AppInfo.version,
    subcommands: [
      ListCommand.self, DisconnectCommand.self, ConnectCommand.self, ExperimentalCommand.self,
    ]
  )
}
