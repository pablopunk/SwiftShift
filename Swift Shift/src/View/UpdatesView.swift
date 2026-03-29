
import SwiftUI
import Sparkle

final class CheckForUpdatesViewModel: ObservableObject {
  @Published var canCheckForUpdates = false
  
  init(updater: SPUUpdater) {
    updater.publisher(for: \.canCheckForUpdates)
      .assign(to: &$canCheckForUpdates)
  }
}

struct CheckUpdatesButton: View {
  @StateObject private var checkForUpdatesViewModel = CheckForUpdatesViewModel(updater: UpdatesManager.shared.updater)
  private var label: String?
  
  init(label: String? = nil) {
    self.label = label
  }
  
  var body: some View {
    Button {
      UpdatesManager.shared.checkForUpdates()
    } label: {
      Image(systemName: "arrow.counterclockwise")
      if let label = label {
        Text(label)
      }
    }
    .disabled(!checkForUpdatesViewModel.canCheckForUpdates)
  }
}

#Preview {
  CheckUpdatesButton(label: "Check for updates").padding()
}
