/// A display known to the system, including disconnected ones: its ID and UUID.
public struct KnownDisplay: Equatable, Sendable {
  public var id: UInt32
  public var uuid: String

  public init(id: UInt32, uuid: String) {
    self.id = id
    self.uuid = uuid
  }
}

public protocol DisplayBackend: Sendable {
  /// Displays that are online right now. The order is not guaranteed.
  func onlineDisplays() throws -> [DisplayInfo]

  /// Removes the display from the layout (`enabled == false`) or adds it back. Performs no safety
  /// checks; that is `DisconnectService`'s job.
  func setEnabled(id: UInt32, enabled: Bool) throws

  /// All displays the system knows about, disconnected ones included (private API). Throws if
  /// unavailable.
  func knownDisplays() throws -> [KnownDisplay]

  /// Sets the layout position of an online display.
  func setOrigin(id: UInt32, x: Int, y: Int) throws
}
