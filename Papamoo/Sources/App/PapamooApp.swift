import SwiftUI
import SwiftData

@main
struct PapamooApp: App {
    private let modelContainer: ModelContainer
    private let viewModelFactory: ViewModelFactory

    init() {
        // 1.0에서 appLanguage만 저장하고 AppleLanguages는 동기화하지 않은 빌드 대비 — 다음 launch에 반영
        LanguagePreference.apply(UserDefaults.appGroup.string(forKey: "appLanguage") ?? "system")

        let schema = Schema(versionedSchema: PapamooSchemaV2.self)
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
        self.viewModelFactory = ViewModelFactory(
            modelContainer: container,
            widgetSnapshotStore: WidgetSnapshotStore(containerURL: appGroupURL)
        )
    }

    var body: some Scene {
        WindowGroup {
            ContentView(
                coordinator: AppCoordinator(),
                factory: viewModelFactory
            )
            .task {
                _ = await NotificationManager.requestAuthorization()
                await ExchangeRateManager.shared.fetchIfStale()
            }
        }
        .modelContainer(modelContainer)
    }
}
