import SwiftUI

struct ExchangeRateSheetView: View {
    @Environment(\.dismiss) private var dismiss
    private let manager = ExchangeRateManager.shared
    @State private var showError = false

    var body: some View {
        NavigationStack {
            List {
                ratesSection
                refreshSection
                networkNotice
            }
            .navigationTitle("Exchange rates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .overlay(alignment: .bottom) {
                if showError, let error = manager.lastError {
                    toastView(message: error)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, 16)
                }
            }
        }
    }

    private var ratesSection: some View {
        Section {
            HStack {
                Text("$1 USD")
                    .font(.body)
                Spacer()
                Text("= ₩\(manager.krwPerUSD)")
                    .font(.body)
                    .fontWeight(.semibold)
                    .monospacedDigit()
            }
            HStack {
                Text("$1 USD")
                    .font(.body)
                Spacer()
                Text("= ¥\(manager.jpyPerUSD)")
                    .font(.body)
                    .fontWeight(.semibold)
                    .monospacedDigit()
            }

            if manager.isUsingFallbackRates {
                Label("Using temporary rates", systemImage: "exclamationmark.triangle")
                    .font(.footnote)
                    .foregroundStyle(.orange)
            }
        }
    }

    private var refreshSection: some View {
        Section {
            Button {
                Task {
                    await manager.fetchLatestRates()
                    if manager.lastError != nil {
                        withAnimation { showError = true }
                        try? await Task.sleep(for: .seconds(3))
                        withAnimation { showError = false }
                    }
                }
            } label: {
                HStack {
                    Label("Refresh rates", systemImage: "arrow.clockwise")
                    Spacer()
                    if manager.isLoading {
                        ProgressView()
                    }
                }
            }
            .disabled(manager.isLoading)

            if let lastUpdated = manager.lastUpdated {
                HStack {
                    Text("Last updated")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(lastUpdated, format: .dateTime.month(.abbreviated).day().hour().minute())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var networkNotice: some View {
        Section {
            Label("Requires network connection for live rates", systemImage: "wifi")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private func toastView(message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "wifi.exclamationmark")
                .font(.footnote)
            Text(message)
                .font(.footnote)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.orange.gradient, in: RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.2), radius: 8, y: 2)
        .padding(.horizontal, 20)
    }
}
