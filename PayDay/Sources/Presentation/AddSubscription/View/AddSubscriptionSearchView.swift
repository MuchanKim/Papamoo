import SwiftUI

struct AddSubscriptionSearchView: View {
    @Bindable var coordinator: AppCoordinator
    @Bindable var viewModel: AddSubscriptionViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchField
                categoryChips
                serviceList
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Add subscription")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { coordinator.dismissAddSubscription() }
                }
            }
            .navigationDestination(item: $viewModel.selectedPreset) { _ in
                AddSubscriptionDetailView(coordinator: coordinator, viewModel: viewModel)
            }
        }
    }

    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.tertiary)
            TextField("Search services", text: $viewModel.searchText)
                .font(.body)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color(.quaternarySystemFill), in: RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                CategoryChip(title: "All", isSelected: viewModel.selectedCategory == nil)
                    .onTapGesture { viewModel.selectedCategory = nil }
                ForEach(SubscriptionCategory.allCases, id: \.self) { category in
                    CategoryChip(title: category.displayName, isSelected: viewModel.selectedCategory == category)
                        .onTapGesture { viewModel.selectedCategory = category }
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 10)
    }

    private var serviceList: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(Array(viewModel.filteredServices.enumerated()), id: \.element.id) { index, service in
                    Button {
                        viewModel.selectPreset(service)
                    } label: {
                        HStack(alignment: .top, spacing: 12) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(service.name)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(PayDayColor.text)
                                Text("\(String(localized: service.category.displayName).uppercased()) · \(viewModel.presetDisplayAmount(service), format: .currency(code: viewModel.baseCurrency).presentation(.narrow).precision(.fractionLength(0)))/MO")
                                    .font(.payDayMeta)
                                    .foregroundStyle(PayDayColor.textMuted)
                                    .tracking(0.6)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 11)
                    }
                    if index < viewModel.filteredServices.count - 1 {
                        Divider().padding(.leading, 16)
                    }
                }
            }
            .background(.background, in: RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 16)

            Button {
                viewModel.selectPreset(PresetService(name: "", category: .other, defaultAmount: 0, iconName: nil))
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "plus").fontWeight(.semibold)
                    Text("Add custom service").fontWeight(.semibold)
                }
                .foregroundStyle(PayDayColor.brand)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(.background, in: RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
        }
    }
}
