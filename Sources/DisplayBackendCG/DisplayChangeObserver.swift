import CoreGraphics

/// Ekran yapılandırması değişince (takma/çıkarma, kesme/bağlama, çözünürlük) `handler`'ı çağırır.
/// Sistem değişikliği iki aşamada bildirir; yalnızca tamamlanmış olanlar iletilir. `handler`
/// bildirimin geldiği iş parçacığında çalışır ve hızlı dönmelidir.
public final class DisplayChangeObserver: @unchecked Sendable {
  fileprivate let handler: @Sendable () -> Void

  public init(handler: @escaping @Sendable () -> Void) {
    self.handler = handler
    CGDisplayRegisterReconfigurationCallback(
      displayReconfigured, Unmanaged.passUnretained(self).toOpaque())
  }

  deinit {
    CGDisplayRemoveReconfigurationCallback(
      displayReconfigured, Unmanaged.passUnretained(self).toOpaque())
  }
}

private let displayReconfigured: CGDisplayReconfigurationCallBack = { _, flags, userInfo in
  guard let userInfo, !flags.contains(.beginConfigurationFlag) else { return }
  Unmanaged<DisplayChangeObserver>.fromOpaque(userInfo).takeUnretainedValue().handler()
}
