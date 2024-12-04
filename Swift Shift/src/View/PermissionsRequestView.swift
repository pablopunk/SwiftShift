import SwiftUI

struct PermissionRequestView: View {
  var body: some View {
    VStack(alignment: .leading) {
      Text("Permissions Required").font(.headline).foregroundStyle(.orange)
      Text("This app requires the following permissions to function properly:")
        .padding(.top, 1)
        .padding(.bottom, 12)
        .lineLimit(2)
      HStack {
        Text("Accessibility").font(.subheadline)
        Image(systemName: "exclamationmark.triangle").foregroundColor(.orange)
        Spacer()
        Button("Open Preferences") {
          PermissionsManager.openPreferences(at: .accessibility)
        }
      }
    }
  }
}

#Preview {
  PermissionRequestView().padding()
}
