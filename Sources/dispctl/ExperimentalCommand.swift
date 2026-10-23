import ArgumentParser
import DisplayBackendCG
import DisplayCore
import Foundation

struct ExperimentalCommand: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "experimental",
    abstract: "Deneysel komutlar (private API). Gerçek ekranı etkiler.",
    subcommands: [Disable.self, Enable.self, Probe.self]
  )

  struct Disable: ParsableCommand {
    static let configuration = CommandConfiguration(
      abstract: "Harici ekranın görüntüsünü keser.")

    @Argument(help: "`dispctl list` çıktısındaki ekran kimliği.")
    var id: UInt32

    @Option(help: "Verilirse bu kadar saniye sonra ekranı kendisi geri açar (1–3600).")
    var revertAfter: Int?

    func validate() throws {
      if let revertAfter, !(1...3600).contains(revertAfter) {
        throw ValidationError("--revert-after 1 ile 3600 arasında olmalı.")
      }
    }

    func run() throws {
      try reportingErrors {
        let service = makeService()
        try service.disable(id)
        print("Ekran \(id) devre dışı bırakıldı.")
        guard let revertAfter else { return }
        print("\(revertAfter) sn sonra geri açılacak; süreç açık kalacak.")
        fflush(stdout)
        Thread.sleep(forTimeInterval: TimeInterval(revertAfter))
        try service.enable(id)
        print("Ekran \(id) geri açıldı.")
      }
    }
  }

  struct Enable: ParsableCommand {
    static let configuration = CommandConfiguration(
      abstract: "Kesilmiş ekranı geri ekler.")

    @Argument(help: "Geri açılacak ekranın kimliği.")
    var id: UInt32

    func run() throws {
      try reportingErrors {
        try makeService().enable(id)
        print("Ekran \(id) geri açıldı.")
      }
    }
  }

  struct Probe: ParsableCommand {
    static let configuration = CommandConfiguration(
      abstract: "Çevrimiçi listeyi ve private CGSGetDisplayList çıktısını yan yana yazar.")

    func run() throws {
      try reportingErrors {
        let backend = CGDisplayBackend()
        let online = try backend.onlineDisplays().map(\.id).sorted()
        print("çevrimiçi (public): \(online)")
        do {
          print("CGSGetDisplayList (private): \(try backend.privateDisplayIDs().sorted())")
        } catch {
          print("CGSGetDisplayList (private): \(error.localizedDescription)")
        }
      }
    }
  }
}
