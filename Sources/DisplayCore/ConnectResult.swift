public struct ConnectResult: Equatable, Sendable {
  /// The display was already online; only the stale record was cleared.
  public var alreadyConnected: Bool
  /// The returned display's position differed from the record and was corrected to match it.
  public var originRestored: Bool
  /// The returned display's size differs from the record; it was not changed, only reported.
  public var sizeDiffers: Bool

  public init(
    alreadyConnected: Bool = false, originRestored: Bool = false, sizeDiffers: Bool = false
  ) {
    self.alreadyConnected = alreadyConnected
    self.originRestored = originRestored
    self.sizeDiffers = sizeDiffers
  }
}
