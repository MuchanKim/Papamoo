import Foundation
import Testing
@testable import Papamoo

@MainActor
struct AppLifecycleSynchronizerTests {

    // MARK: - Methods

    @Test("가져오기 실패 전에도 기존 구독을 먼저 조회한다")
    func refreshesExistingSubscriptionsBeforeImportFailure() async {
        let recorder = OperationRecorder()
        let synchronizer = makeSynchronizer(
            recorder: recorder,
            importPendingSubscriptions: {
                throw TestError.importFailed
            }
        )

        do {
            try await synchronizer.synchronizeOnActivation()
            Issue.record("가져오기 오류가 전달되어야 합니다.")
        } catch TestError.importFailed {
            #expect(recorder.operations == [.refresh, .importPending])
        } catch {
            Issue.record("예상하지 못한 오류입니다: \(error)")
        }
    }

    @Test("가져오기 성공 후 전체 동기화를 순서대로 완료한다")
    func synchronizesInOrderAfterImportSuccess() async throws {
        let recorder = OperationRecorder()
        let synchronizer = makeSynchronizer(
            recorder: recorder,
            importPendingSubscriptions: {}
        )

        try await synchronizer.synchronizeOnActivation()

        #expect(recorder.operations == [
            .refresh,
            .importPending,
            .refresh,
            .notifications,
            .widget,
        ])
    }

    // MARK: - Private Methods

    private func makeSynchronizer(
        recorder: OperationRecorder,
        importPendingSubscriptions: @escaping () async throws -> Void
    ) -> AppLifecycleSynchronizer {
        AppLifecycleSynchronizer(
            operations: .init(
                refreshSubscriptions: {
                    recorder.operations.append(.refresh)
                },
                importPendingSubscriptions: {
                    recorder.operations.append(.importPending)
                    try await importPendingSubscriptions()
                },
                synchronizeNotifications: {
                    recorder.operations.append(.notifications)
                },
                synchronizeWidgetSnapshot: {
                    recorder.operations.append(.widget)
                }
            )
        )
    }
}

// MARK: - Private Methods

private extension AppLifecycleSynchronizerTests {
    enum Operation: Equatable {
        case refresh
        case importPending
        case notifications
        case widget
    }

    enum TestError: Error {
        case importFailed
    }

    final class OperationRecorder {
        var operations: [Operation] = []
    }
}
