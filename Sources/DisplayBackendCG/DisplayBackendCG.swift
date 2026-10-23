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

  public func setEnabled(id: UInt32, enabled: Bool) throws {
    let configure = try PrivateAPI.configureDisplayEnabled()
    var config: CGDisplayConfigRef?
    var result = CGBeginDisplayConfiguration(&config)
    guard result == .success else { throw Self.failure(result, "CGBeginDisplayConfiguration") }

    result = configure(config, id, enabled)
    guard result == .success else {
      CGCancelDisplayConfiguration(config)
      throw Self.failure(result, "CGSConfigureDisplayEnabled")
    }

    result = CGCompleteDisplayConfiguration(config, .forSession)
    guard result == .success else { throw Self.failure(result, "CGCompleteDisplayConfiguration") }
  }

  public func knownDisplays() throws -> [KnownDisplay] {
    try privateDisplayIDs().map { KnownDisplay(id: $0, uuid: Self.uuid(of: $0)) }
  }

  public func setOrigin(id: UInt32, x: Int, y: Int) throws {
    var config: CGDisplayConfigRef?
    var result = CGBeginDisplayConfiguration(&config)
    guard result == .success else { throw Self.failure(result, "CGBeginDisplayConfiguration") }

    result = CGConfigureDisplayOrigin(config, id, Int32(clamping: x), Int32(clamping: y))
    guard result == .success else {
      CGCancelDisplayConfiguration(config)
      throw Self.failure(result, "CGConfigureDisplayOrigin")
    }

    result = CGCompleteDisplayConfiguration(config, .forSession)
    guard result == .success else { throw Self.failure(result, "CGCompleteDisplayConfiguration") }
  }

  /// Deneysel (S3, S4): private `CGSGetDisplayList`'in döndürdüğü kimlikler. Kesilmiş ekranı da
  /// içerip içermediğini gözlemlemek için; üretim yolunda kullanılmaz.
  public func privateDisplayIDs() throws -> [UInt32] {
    let list = try PrivateAPI.getDisplayList()
    var ids = [CGDirectDisplayID](repeating: 0, count: 32)
    var count: UInt32 = 0
    let result = list(UInt32(ids.count), &ids, &count)
    guard result == .success else { throw Self.failure(result, "CGSGetDisplayList") }
    return Array(ids.prefix(min(Int(count), ids.count)))
  }

  private static func failure(_ error: CGError, _ call: String = "CGGetOnlineDisplayList")
    -> DisplayError
  {
    .backendFailure("\(call) hata kodu \(error.rawValue)")
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
