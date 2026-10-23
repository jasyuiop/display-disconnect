public struct DisplayInfo: Codable, Equatable, Sendable {
  public var id: UInt32
  public var uuid: String
  public var name: String
  public var isBuiltin: Bool
  public var isMain: Bool
  public var x: Int
  public var y: Int
  public var width: Int
  public var height: Int

  public init(
    id: UInt32, uuid: String, name: String, isBuiltin: Bool, isMain: Bool,
    x: Int, y: Int, width: Int, height: Int
  ) {
    self.id = id
    self.uuid = uuid
    self.name = name
    self.isBuiltin = isBuiltin
    self.isMain = isMain
    self.x = x
    self.y = y
    self.width = width
    self.height = height
  }
}
