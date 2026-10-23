import AppKit
import DisplayCore
import SwiftUI

struct MenuContent: View {
  let model: DisplaysModel

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      if model.rows.isEmpty && model.errorMessage == nil {
        Text("Bağlı ekran yok.")
      }
      ForEach(model.rows) { row in
        HStack {
          VStack(alignment: .leading, spacing: 2) {
            Text(row.title)
            Text(row.subtitle).font(.caption).foregroundStyle(.secondary)
          }
          .opacity(row.isDisconnected ? 0.6 : 1)
          Spacer()
          if let action = row.action {
            Button(label(for: action)) { model.perform(action, on: row.id) }
              .disabled(model.busyID != nil)
          }
        }
      }
      if let message = model.errorMessage {
        Text(message).font(.caption).foregroundStyle(.red)
          .fixedSize(horizontal: false, vertical: true)
      }
      Divider()
      HStack {
        Button("Yenile") { model.reload() }
        Spacer()
        Button("Çık") { NSApplication.shared.terminate(nil) }
      }
    }
    .padding(12)
    .frame(minWidth: 300, alignment: .leading)
    .onAppear { model.refresh() }
  }

  private func label(for action: RowAction) -> String {
    switch action {
    case .disconnect: "Bağlantıyı kes"
    case .connect: "Bağla"
    }
  }
}
