public enum RowAction: Equatable, Sendable {
  case disconnect
  case connect
}

public struct DisplayRow: Equatable, Identifiable, Sendable {
  public var id: UInt32
  public var title: String
  public var subtitle: String
  public var isDisconnected: Bool
  /// The only action the row offers; without one, no button is shown.
  public var action: RowAction?

  public init(
    id: UInt32, title: String, subtitle: String, isDisconnected: Bool, action: RowAction?
  ) {
    self.id = id
    self.title = title
    self.subtitle = subtitle
    self.isDisconnected = isDisconnected
    self.action = action
  }
}

/// Builds the rows of the menu bar list; the UI layer only draws them.
public enum DisplayMenuPresenter {
  public static func rows(_ displays: [DisplayInfo]) -> [DisplayRow] {
    let connectedCount = displays.filter { $0.state == .connected }.count
    return displays.map { display in
      var parts = ["\(display.width)×\(display.height)"]
      if display.isMain { parts.append("main display") }
      if display.isBuiltin { parts.append("built-in") }
      if display.state == .disconnected { parts.append("disconnected") }
      return DisplayRow(
        id: display.id,
        title: display.name,
        subtitle: parts.joined(separator: " · "),
        isDisconnected: display.state == .disconnected,
        action: action(for: display, connectedCount: connectedCount))
    }
  }

  /// The service enforces the same rules anyway; this only avoids offering an action that
  /// would be refused.
  private static func action(for display: DisplayInfo, connectedCount: Int) -> RowAction? {
    if display.state == .disconnected { return .connect }
    if display.isBuiltin || connectedCount < 2 { return nil }
    return .disconnect
  }
}
