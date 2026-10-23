import ArgumentParser
import DisplayCore

@main
struct Dispctl: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "dispctl",
    abstract: "Harici ekranların görüntü bağlantısını yönetir.",
    version: AppInfo.version,
    subcommands: [ListCommand.self, ExperimentalCommand.self]
  )
}
