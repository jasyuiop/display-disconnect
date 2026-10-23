public struct DisconnectService: Sendable {
  private let backend: any DisplayBackend

  public init(backend: any DisplayBackend) {
    self.backend = backend
  }

  public func list() throws -> [DisplayInfo] {
    try call { try backend.onlineDisplays().sorted { $0.id < $1.id } }
  }

  /// Harici ekranın görüntüsünü keser. Son ekranı ve dahili ekranı reddeder.
  public func disable(_ id: UInt32) throws {
    let displays = try list()
    guard let target = displays.first(where: { $0.id == id }) else {
      throw DisplayError.unknownDisplay(id)
    }
    guard displays.count > 1 else { throw DisplayError.lastDisplay }
    guard !target.isBuiltin else { throw DisplayError.builtinNotAllowed }
    try call { try backend.setEnabled(id: id, enabled: false) }
  }

  /// Kesilmiş ekranı geri ekler. Kesilmiş ekran çevrimiçi listede olmadığı için varlığı denetlenmez.
  public func enable(_ id: UInt32) throws {
    try call { try backend.setEnabled(id: id, enabled: true) }
  }

  private func call<T>(_ body: () throws -> T) throws -> T {
    do {
      return try body()
    } catch let error as DisplayError {
      throw error
    } catch {
      throw DisplayError.backendFailure(String(describing: error))
    }
  }
}
