import AppKit
import CoreGraphics
import DisplayCore

// Yalnızca public API. Private API FAZ1.3'te PrivateAPI.swift'e eklenir.
public struct CGDisplayBackend: DisplayBackend {
  public init() {}

  public func onlineDisplays() throws -> [DisplayInfo] {
    var count: UInt32 = 0
    var result = CGGetOnlineDisplayList(0, nil, &count)
    guard result == .success else { throw Self.failure(result) }

    var ids = [CGDirectDisplayID](repeating: 0, count: Int(count))
    result = CGGetOnlineDisplayList(count, &ids, &count)
    guard result == .success else { throw Self.failure(result) }

    let names = Self.screenNames()
    return ids.prefix(Int(count)).map { id in
      let bounds = CGDisplayBounds(id)
      return DisplayInfo(
        id: id,
        uuid: Self.uuid(of: id),
        name: names[id] ?? "Display \(id)",
        isBuiltin: CGDisplayIsBuiltin(id) != 0,
        isMain: CGDisplayIsMain(id) != 0,
        x: Int(bounds.origin.x), y: Int(bounds.origin.y),
        width: Int(bounds.width), height: Int(bounds.height))
    }
  }

  private static func failure(_ error: CGError) -> DisplayError {
    .backendFailure("CGGetOnlineDisplayList hata kodu \(error.rawValue)")
  }

  private static func uuid(of id: CGDirectDisplayID) -> String {
    guard let uuid = CGDisplayCreateUUIDFromDisplayID(id)?.takeRetainedValue() else { return "" }
    return CFUUIDCreateString(nil, uuid) as String
  }

  /// NSScreen yalnızca ana iş parçacığında okunur; değilse ad bulunamaz ve yedek ad kullanılır.
  private static func screenNames() -> [CGDirectDisplayID: String] {
    guard Thread.isMainThread else { return [:] }
    return MainActor.assumeIsolated {
      var names: [CGDirectDisplayID: String] = [:]
      for screen in NSScreen.screens {
        let key = NSDeviceDescriptionKey("NSScreenNumber")
        if let number = screen.deviceDescription[key] as? NSNumber {
          names[number.uint32Value] = screen.localizedName
        }
      }
      return names
    }
  }
}
