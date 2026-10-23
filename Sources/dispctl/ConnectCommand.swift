import ArgumentParser

struct ConnectCommand: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "connect",
    abstract: "Kesilmiş ekranı geri bağlar ve eski düzenine döndürür."
  )

  @Argument(help: "`dispctl list` çıktısında `disconnected` görünen ekran kimliği.")
  var id: UInt32

  func run() throws {
    let result = try makeService().connect(id)
    if result.alreadyConnected {
      print("Ekran \(id) zaten bağlıydı; eski kayıt temizlendi.")
      return
    }
    print("Ekran \(id) geri bağlandı.")
    if result.originRestored { print("Konumu kayıtlı düzene göre düzeltildi.") }
    if result.sizeDiffers {
      print("Uyarı: boyutu kayıttakinden farklı; değiştirilmedi. `dispctl list` ile bakın.")
    }
  }
}
