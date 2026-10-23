import Foundation

public struct DisconnectService: Sendable {
  private let backend: any DisplayBackend
  private let store: any StateStore
  private let now: @Sendable () -> Date

  public init(
    backend: any DisplayBackend,
    store: any StateStore,
    now: @escaping @Sendable () -> Date = { Date() }
  ) {
    self.backend = backend
    self.store = store
    self.now = now
  }

  /// Çevrimiçi ekranlar ile kayıtlı ama çevrimiçi olmayan (kesilmiş) ekranlar. Salt okunur.
  public func list() throws -> [DisplayInfo] {
    let online = try onlineDisplays()
    let onlineUUIDs = Set(online.map(\.uuid))
    let disconnected = try loadState().records.map(\.display)
      .filter { !onlineUUIDs.contains($0.uuid) }
      .map { display in
        var copy = display
        copy.state = .disconnected
        return copy
      }
    return (online + disconnected).sorted { $0.id < $1.id }
  }

  /// Harici ekranın görüntüsünü keser ve geri bağlanabilmesi için kaydını yazar.
  /// Önce kayıt yazılır; kesme başarısız olursa kayıt geri alınır.
  public func disconnect(_ id: UInt32) throws {
    let target = try validatedTarget(id)
    guard !target.uuid.isEmpty else { throw DisplayError.missingUUID(id) }

    let previous = try loadState()
    var updated = previous
    updated.records.removeAll { $0.display.uuid == target.uuid }
    updated.records.append(DisconnectedRecord(display: target, disconnectedAt: now()))
    try saveState(updated)

    do {
      try call { try backend.setEnabled(id: id, enabled: false) }
    } catch {
      // Asıl hata `error`; geri alma da başarısız olursa kayıt kalır, ama bir sonraki
      // `list` çevrimiçi ekranı UUID ile eşleştirip kaydı yok sayar.
      try? store.save(previous)
      throw error
    }
  }

  /// Deneysel, durumsuz kesme (`dispctl experimental disable`). Aynı güvenlik denetimleri.
  public func disable(_ id: UInt32) throws {
    _ = try validatedTarget(id)
    try call { try backend.setEnabled(id: id, enabled: false) }
  }

  /// Kesilmiş ekranı geri ekler. Kesilmiş ekran çevrimiçi listede olmadığı için varlığı denetlenmez.
  public func enable(_ id: UInt32) throws {
    try call { try backend.setEnabled(id: id, enabled: true) }
  }

  private func validatedTarget(_ id: UInt32) throws -> DisplayInfo {
    let online = try onlineDisplays()
    guard let target = online.first(where: { $0.id == id }) else {
      throw DisplayError.unknownDisplay(id)
    }
    guard online.count > 1 else { throw DisplayError.lastDisplay }
    guard !target.isBuiltin else { throw DisplayError.builtinNotAllowed }
    return target
  }

  private func onlineDisplays() throws -> [DisplayInfo] {
    try call { try backend.onlineDisplays().sorted { $0.id < $1.id } }
  }

  private func loadState() throws -> DisconnectState {
    do {
      return try store.load()
    } catch let error as DisplayError {
      throw error
    } catch {
      throw DisplayError.stateFailure(String(describing: error))
    }
  }

  private func saveState(_ state: DisconnectState) throws {
    do {
      try store.save(state)
    } catch let error as DisplayError {
      throw error
    } catch {
      throw DisplayError.stateFailure(String(describing: error))
    }
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
