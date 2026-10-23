import ArgumentParser
import DisplayCore

struct ListCommand: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "list",
    abstract: "List connected displays, and displays this tool has disconnected."
  )

  @Flag(help: "Print the output as JSON.")
  var json = false

  func run() throws {
    try reportingErrors {
      let displays = try makeService().list()
      print(json ? try DisplayListFormatter.json(displays) : DisplayListFormatter.text(displays))
    }
  }
}
