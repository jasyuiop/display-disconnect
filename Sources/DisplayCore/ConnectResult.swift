public struct ConnectResult: Equatable, Sendable {
  /// Ekran zaten çevrimiçiydi; yalnızca eski kayıt temizlendi.
  public var alreadyConnected: Bool
  /// Geri gelen ekranın konumu kayıttan farklıydı ve kayda göre düzeltildi.
  public var originRestored: Bool
  /// Geri gelen ekranın boyutu kayıttan farklı; değiştirilmedi, yalnızca bildirildi.
  public var sizeDiffers: Bool

  public init(
    alreadyConnected: Bool = false, originRestored: Bool = false, sizeDiffers: Bool = false
  ) {
    self.alreadyConnected = alreadyConnected
    self.originRestored = originRestored
    self.sizeDiffers = sizeDiffers
  }
}
