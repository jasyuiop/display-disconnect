import DisplayBackendCG
import DisplayCore
import DisplayStorage

func makeService() -> DisconnectService {
  DisconnectService(
    backend: CGDisplayBackend(),
    store: FileStateStore(url: FileStateStore.defaultURL))
}
