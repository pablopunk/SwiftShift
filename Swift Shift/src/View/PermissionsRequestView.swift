import SwiftUI

struct PermissionRequestView: View {
  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack(spacing: 6) {
        Image(systemName: "exclamationmark.triangle.fill")
          .foregroundStyle(.orange)
        Text("Permissions Required")
          .font(.system(size: 13, weight: .semibold))
      }

      Text("Swift Shift needs Accessibility access to manage windows.")
        .font(.system(size: 11))
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)

      Button {
        PermissionsManager.openPreferences(at: .accessibility)
      } label: {
        HStack(spacing: 4) {
          Image(systemName: "lock.open")
          Text("Grant Access")
        }
        .font(.system(size: 12, weight: .medium))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 7)
        .background(.orange.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 8))
      }
      .buttonStyle(.plain)
      .foregroundStyle(.orange)
    }
    .padding(12)
    .background(.orange.opacity(0.05))
    .clipShape(RoundedRectangle(cornerRadius: 10))
  }
}

#Preview {
  PermissionRequestView().padding().frame(width: 300)
}
