import Foundation

public struct DisconnectService: Sendable {
  private let backend: any DisplayBackend
  private let store: any StateStore
  private let now: @Sendable () -> Date
  private let sleep: @Sendable (TimeInterval) -> Void

  private static let verifyAttempts = 10
  private static let verifyInterval: TimeInterval = 0.5

  public init(
    backend: any DisplayBackend,
    store: any StateStore,
    now: @escaping @Sendable () -> Date = { Date() },
    sleep: @escaping @Sendable (TimeInterval) -> Void = { Thread.sleep(forTimeInterval: $0) }
  ) {
    self.backend = backend
    self.store = store
    self.now = now
    self.sleep = sleep
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

  /// Kesilmiş ekranı geri bağlar: kaydı UUID ile çözer, ekranın gerçekten döndüğünü doğrular,
  /// konum kayıttan farklıysa düzeltir ve kaydı siler. Ekran dönmezse kayıt korunur.
  @discardableResult
  public func connect(_ id: UInt32) throws -> ConnectResult {
    let state = try loadState()
    guard let recorded = state.records.first(where: { $0.display.id == id })?.display else {
      throw DisplayError.notDisconnected(id)
    }

    if try onlineDisplay(uuid: recorded.uuid) != nil {
      try saveState(state, removing: recorded.uuid, afterConnect: false)
      return ConnectResult(alreadyConnected: true)
    }

    try call { try backend.setEnabled(id: currentID(of: recorded), enabled: true) }
    guard let appeared = try waitForDisplay(uuid: recorded.uuid) else {
      throw DisplayError.backendFailure(
        "Geri bağlama komutu verildi ama ekran birkaç saniye içinde görünmedi; kayıt korundu. "
          + "`dispctl list` ile bakın.")
    }

    var result = ConnectResult()
    if appeared.x != recorded.x || appeared.y != recorded.y {
      try call { try backend.setOrigin(id: appeared.id, x: recorded.x, y: recorded.y) }
      result.originRestored = true
    }
    result.sizeDiffers = appeared.width != recorded.width || appeared.height != recorded.height
    try saveState(state, removing: recorded.uuid, afterConnect: true)
    return result
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

  /// Kayıttaki UUID'nin şu anki kimliği. Private liste yoksa kayıtlı kimlikle devam edilir;
  /// asıl işlem (`setEnabled`) kendi hatasını bildirir. UUID eşleşmeyen kimliklere dokunulmaz.
  private func currentID(of recorded: DisplayInfo) -> UInt32 {
    guard !recorded.uuid.isEmpty, let known = try? backend.knownDisplays() else {
      return recorded.id
    }
    return known.first { $0.uuid == recorded.uuid }?.id ?? recorded.id
  }

  private func onlineDisplay(uuid: String) throws -> DisplayInfo? {
    guard !uuid.isEmpty else { return nil }
    return try onlineDisplays().first { $0.uuid == uuid }
  }

  private func waitForDisplay(uuid: String) throws -> DisplayInfo? {
    for attempt in 0..<Self.verifyAttempts {
      if let display = try onlineDisplay(uuid: uuid) { return display }
      if attempt < Self.verifyAttempts - 1 { sleep(Self.verifyInterval) }
    }
    return nil
  }

  private func saveState(
    _ state: DisconnectState, removing uuid: String, afterConnect: Bool
  ) throws {
    var updated = state
    updated.records.removeAll { $0.display.uuid == uuid }
    do {
      try saveState(updated)
    } catch DisplayError.stateFailure(let reason) where afterConnect {
      throw DisplayError.stateFailure("ekran geri bağlandı ama kayıt temizlenemedi: \(reason)")
    }
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
