import ArgumentParser

struct DisconnectCommand: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "disconnect",
    abstract: "Harici ekranın görüntü bağlantısını keser (şarj sürer)."
  )

  @Argument(help: "`dispctl list` çıktısındaki ekran kimliği.")
  var id: UInt32

  func run() throws {
    try makeService().disconnect(id)
    print("Ekran \(id) bağlantısı kesildi. Geri bağlamak için: dispctl connect \(id)")
  }
}
