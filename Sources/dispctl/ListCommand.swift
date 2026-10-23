import ArgumentParser
import DisplayBackendCG
import DisplayCore

struct ListCommand: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "list",
    abstract: "Bağlı ekranları listeler."
  )

  @Flag(help: "Çıktıyı JSON olarak yazar.")
  var json = false

  func run() throws {
    let displays = try DisconnectService(backend: CGDisplayBackend()).list()
    print(json ? try DisplayListFormatter.json(displays) : DisplayListFormatter.text(displays))
  }
}
