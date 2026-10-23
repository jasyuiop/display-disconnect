import CoreGraphics

/// Calls `handler` when the display configuration changes (plug/unplug, disconnect/connect,
/// resolution). The system reports a change in two phases; only completed ones are forwarded.
/// `handler` runs on the thread that delivers the notification and should return quickly.
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
