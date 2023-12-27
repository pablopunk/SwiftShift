import SwiftUI

struct PermissionRequestView: View {
    var body: some View {
        VStack {
            Text("Permissions Required").font(.headline).foregroundStyle(.orange)
            Text("This app requires the following permissions to function properly")
                .padding(.top, 1)
                .padding(.bottom, 12)
            HStack {
                Text("Accessibility").font(.subheadline)
                Spacer()
                Button("Open Preferences") {
                    PermissionsManager.openPreferences(at: .accessibility)
                }
            }
        }.frame(width: 230)
    }
}

#Preview {
    PermissionRequestView()
}
