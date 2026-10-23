/// Menubar penceresinin durumu. Liste hatası ve eylem hatası ayrı tutulur: başarılı bir liste
/// yenilemesi, kullanıcının henüz görmediği eylem hatasını silmemelidir.
public struct MenuState: Equatable, Sendable {
  public private(set) var rows: [DisplayRow] = []
  /// Eylemi süren ekranın kimliği; bu sırada başka eylem başlatılmaz.
  public private(set) var busyID: UInt32?
  private var listError: String?
  private var actionError: String?

  public init() {}

  public var errorMessage: String? { actionError ?? listError }

  public mutating func listLoaded(_ displays: [DisplayInfo]) {
    rows = DisplayMenuPresenter.rows(displays)
    listError = nil
  }

  public mutating func listFailed(_ message: String) {
    rows = []
    listError = message
  }

  /// Meşgulse `false` döner ve hiçbir şeyi değiştirmez.
  public mutating func beginAction(on id: UInt32) -> Bool {
    guard busyID == nil else { return false }
    busyID = id
    actionError = nil
    return true
  }

  public mutating func finishAction(failure: String?) {
    busyID = nil
    actionError = failure
  }

  public mutating func dismissActionError() {
    actionError = nil
  }
}
