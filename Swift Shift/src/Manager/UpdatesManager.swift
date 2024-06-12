import Sparkle

class UpdatesManager {
    static var shared = UpdatesManager()
    let controller: SPUStandardUpdaterController
    let updater: SPUUpdater
    
    init() {
        self.controller = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
        self.updater = controller.updater
    }
    
    func checkForUpdates() {
        return self.updater.checkForUpdates()
    }
}
