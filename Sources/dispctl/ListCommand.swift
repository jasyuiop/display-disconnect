import ArgumentParser
import DisplayCore

struct ListCommand: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "list",
    abstract: "Bağlı ekranları listeler."
  )

  @Flag(help: "Çıktıyı JSON olarak yazar.")
  var json = false

  func run() throws {
    try reportingErrors {
      let displays = try makeService().list()
      print(json ? try DisplayListFormatter.json(displays) : DisplayListFormatter.text(displays))
    }
  }
}
