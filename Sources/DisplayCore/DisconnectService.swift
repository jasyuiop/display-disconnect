public struct DisconnectService: Sendable {
  private let backend: any DisplayBackend

  public init(backend: any DisplayBackend) {
    self.backend = backend
  }

  public func list() throws -> [DisplayInfo] {
    do {
      return try backend.onlineDisplays().sorted { $0.id < $1.id }
    } catch let error as DisplayError {
      throw error
    } catch {
      throw DisplayError.backendFailure(String(describing: error))
    }
  }
}
