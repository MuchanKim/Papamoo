import SwiftUI
import SwiftData

@main
struct PapamooApp: App {
    private let modelContainer: ModelContainer

    init() {
        // 1.0에서 appLanguage만 저장하고 AppleLanguages는 동기화하지 않은 빌드 대비 — 다음 launch에 반영
        LanguagePreference.apply(UserDefaults.appGroup.string(forKey: "appLanguage") ?? "system")

        let config = ModelConfiguration(
            groupContainer: .identifier(AppGroup.identifier),
            cloudKitDatabase: .none  // CloudKit은 container provisioning 완료 후 .automatic으로 변경
        )
        do {
            self.modelContainer = try ModelContainer(for: Subscription.self, configurations: config)
        } catch {
            // 스키마 변경으로 기존 DB 호환 불가 시 기존 데이터 삭제 후 재생성
            try? FileManager.default.removeItem(at: config.url)
            self.modelContainer = try! ModelContainer(for: Subscription.self, configurations: config)
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView(
                coordinator: AppCoordinator(),
                factory: ViewModelFactory(modelContext: modelContainer.mainContext)
            )
            .task {
                _ = await NotificationManager.requestAuthorization()
            }
        }
        .modelContainer(modelContainer)
    }
}
