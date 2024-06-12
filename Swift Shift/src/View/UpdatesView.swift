
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
    @ObservedObject private var checkForUpdatesViewModel: CheckForUpdatesViewModel
    private var label: String?

    init(label: String? = nil) {
        self.checkForUpdatesViewModel = CheckForUpdatesViewModel(updater: UpdatesManager.shared.updater)
        if label != nil {
            self.label = label
        }
    }

    var body: some View {
        Button {
            UpdatesManager.shared.checkForUpdates()
        } label: {
            Image(systemName: "arrow.counterclockwise")
                .disabled(!checkForUpdatesViewModel.canCheckForUpdates)
            if label != nil {
                Text(label!)
            }
        }
    }
}

#Preview {
    CheckUpdatesButton(label: "Check for updates").padding()
}
