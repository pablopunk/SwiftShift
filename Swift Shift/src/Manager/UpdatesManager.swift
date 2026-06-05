import Sparkle
import AppKit

class UpdatesManager: NSObject, SPUStandardUserDriverDelegate {
  static let shared = UpdatesManager()
  lazy var controller = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: self)
  lazy var updater = controller.updater
  private var presentedUpdateUI = false
  
  var supportsGentleScheduledUpdateReminders: Bool {
    true
  }

  override private init() {
    super.init()
  }
  
  func checkForUpdates() {
    return self.updater.checkForUpdates()
  }

  func standardUserDriverWillHandleShowingUpdate(_ handleShowingUpdate: Bool, forUpdate update: SUAppcastItem, state: SPUUserUpdateState) {
    guard handleShowingUpdate else { return }
    presentedUpdateUI = true
    NSApp.setActivationPolicy(.regular)

    if !state.userInitiated {
      NSApp.dockTile.badgeLabel = "1"
    }
  }

  func standardUserDriverDidReceiveUserAttention(forUpdate update: SUAppcastItem) {
    clearUpdateAttention()
  }

  func standardUserDriverWillFinishUpdateSession() {
    clearUpdateAttention()

    if presentedUpdateUI {
      NSApp.setActivationPolicy(.accessory)
      presentedUpdateUI = false
    }
  }

  private func clearUpdateAttention() {
    NSApp.dockTile.badgeLabel = nil
  }
}
