import Foundation

public enum DisplayListFormatter {
  public static func text(_ displays: [DisplayInfo]) -> String {
    guard !displays.isEmpty else { return "Bağlı ekran yok." }
    return displays.map { display in
      var line = "\(display.id)  \(display.name)  \(display.uuid)"
      line += "  \(display.width)x\(display.height)+\(display.x)+\(display.y)"
      if display.isMain { line += "  main" }
      if display.isBuiltin { line += "  builtin" }
      if display.state == .disconnected { line += "  disconnected" }
      return line
    }.joined(separator: "\n")
  }

  public static func json(_ displays: [DisplayInfo]) throws -> String {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    return String(decoding: try encoder.encode(displays), as: UTF8.self)
  }
}
