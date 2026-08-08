import SwiftUI
import SwiftData

@main
struct PapamooApp: App {

    @State private var coordinator = AppCoordinator()
    private let modelContainer: ModelContainer
    private let appContainer: AppContainer

    init() {
        // 1.0이 appLanguage만 저장했던 호환 문제를 다음 실행부터 복구한다.
        LanguagePreference.apply(
            UserDefaults.appGroup.string(forKey: "appLanguage") ?? LanguagePreference.defaultSelection
        )

        let schema = Schema(versionedSchema: PapamooSchemaV3.self)
        let config = ModelConfiguration(
            schema: schema,
            groupContainer: .identifier(AppGroup.identifier),
            cloudKitDatabase: .none  // CloudKit은 container provisioning 완료 후 .automatic으로 변경
        )
        let container: ModelContainer
        do {
            container = try ModelContainer(
                for: schema,
                migrationPlan: PapamooMigrationPlan.self,
                configurations: [config]
            )
        } catch {
            fatalError("Failed to initialize the subscription store: \(error)")
        }
        self.modelContainer = container

        guard let appGroupURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: AppGroup.identifier
        ) else {
            fatalError("Failed to access the Papamoo App Group container")
        }
        self.appContainer = AppContainer(
            modelContainer: container,
            widgetSnapshotStore: WidgetSnapshotStore(containerURL: appGroupURL)
        )
    }

    var body: some Scene {
        WindowGroup {
            ContentView(
                coordinator: coordinator,
                appContainer: appContainer
            )
            .task {
                await ExchangeRateManager.shared.fetchIfStale()
            }
        }
        .modelContainer(modelContainer)
    }
}
