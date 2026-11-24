import Foundation
import Observation

@MainActor
@Observable
final class MiniAppSelectionStore {
    private(set) var selected: MiniApp

    private let userDefaults: UserDefaults
    private let selectableMiniApps: Set<MiniApp>
    private let selectionKey = "selectedMiniApp"

    init(
        userDefaults: UserDefaults = .standard,
        selectableMiniApps: Set<MiniApp> = Set(MiniApp.allCases.filter(\.isAvailable))
    ) {
        self.userDefaults = userDefaults
        self.selectableMiniApps = selectableMiniApps
        if let rawValue = userDefaults.string(forKey: selectionKey),
            let miniApp = MiniApp(rawValue: rawValue),
            selectableMiniApps.contains(miniApp)
        {
            selected = miniApp
        } else {
            selected = .todos
        }
    }

    func select(_ miniApp: MiniApp) {
        guard selectableMiniApps.contains(miniApp) else { return }
        selected = miniApp
        userDefaults.set(miniApp.rawValue, forKey: selectionKey)
    }
}
