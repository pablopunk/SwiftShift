
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

    init() {
        self.checkForUpdatesViewModel = CheckForUpdatesViewModel(updater: UpdatesManager.shared.updater)
    }

    var body: some View {
        Button {
            UpdatesManager.shared.checkForUpdates()
        } label: {
            Image(systemName: "arrow.counterclockwise")
                .disabled(!checkForUpdatesViewModel.canCheckForUpdates)
        }
        .buttonStyle(.borderless)
    }
}

#Preview {
    CheckUpdatesButton().padding()
}
