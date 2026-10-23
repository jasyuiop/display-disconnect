import AppKit
import DisplayCore
import SwiftUI

struct MenuContent: View {
  let model: DisplaysModel

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      if let message = model.errorMessage {
        Text(message).foregroundStyle(.red).fixedSize(horizontal: false, vertical: true)
      } else if model.rows.isEmpty {
        Text("Bağlı ekran yok.")
      } else {
        ForEach(model.rows) { row in
          VStack(alignment: .leading, spacing: 2) {
            Text(row.title)
            Text(row.subtitle).font(.caption).foregroundStyle(.secondary)
          }
          .opacity(row.isDisconnected ? 0.6 : 1)
        }
      }
      Divider()
      HStack {
        Button("Yenile") { model.refresh() }
        Spacer()
        Button("Çık") { NSApplication.shared.terminate(nil) }
      }
    }
    .padding(12)
    .frame(minWidth: 260, alignment: .leading)
    .onAppear { model.refresh() }
  }
}
