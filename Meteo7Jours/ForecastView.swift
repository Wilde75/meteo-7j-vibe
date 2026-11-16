import SwiftUI

struct ForecastView: View {
    @EnvironmentObject var cityStore: CityStore
    @EnvironmentObject var viewModel: WeatherViewModel
    @State private var showSettings = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header
            if viewModel.daily.isEmpty, let message = viewModel.message {
                Text(message)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                todaySection
                Divider()
                daysList
            }
            footer
        }
        .frame(width: 340)
        .padding(12)
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(cityStore)
        }
    }

    private var header: some View {
        HStack {
            Picker("Ville", selection: Binding(
                get: { cityStore.selectedCityID ?? "" },
                set: { newValue in
                    if let city = cityStore.cities.first(where: { $0.id == newValue }) {
                        cityStore.select(city)
                        Task { await viewModel.refresh() }
                    }
                }
            )) {
                ForEach(cityStore.cities) { city in
                    Text(city.name + (city.isDefault ? "  •  domicile" : "")).tag(city.id)
                }
            }
            .labelsHidden()
            Spacer()
            if viewModel.isLoading {
                ProgressView().controlSize(.small)
            }
        }
    }

    private var todaySection: some View {
        let today = viewModel.daily.first
        let temperature = viewModel.observation?.temperature ?? viewModel.current?.temperature
        let desc = viewModel.observation?.weatherDescription
            ?? viewModel.current?.weatherDesc
            ?? today?.weatherDesc
        let icon = WeatherIcon.symbol(
            icon: viewModel.observation?.weatherIcon ?? viewModel.current?.weatherIcon ?? today?.weatherIcon,
            desc: desc ?? today?.weatherDesc
        )
        return HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 34))
                .symbolRenderingMode(.hierarchical)
            VStack(alignment: .leading, spacing: 2) {
                Text(cityStore.selectedCity?.name ?? "")
                    .font(.headline)
                if let temperature {
                    Text("\(Int(temperature.rounded()))°" + (desc.map { " — \($0)" } ?? ""))
                        .font(.subheadline)
                } else if let desc {
                    Text(desc).font(.subheadline)
                }
                if let today, let tmin = today.tmin, let tmax = today.tmax {
                    Text("Min \(Int(tmin.rounded()))° / Max \(Int(tmax.rounded()))°")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var daysList: some View {
        VStack(spacing: 6) {
            ForEach(viewModel.daily) { day in
                HStack(spacing: 10) {
                    Text(dayLabel(for: day))
                        .frame(width: 92, alignment: .leading)
                    Image(systemName: WeatherIcon.symbol(icon: day.weatherIcon, desc: day.weatherDesc))
                        .frame(width: 24)
                    Text(day.weatherDesc ?? "")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Spacer()
                    if let probability = day.rainProbability {
                        Label("\(probability) %", systemImage: "drop")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                    if let tmin = day.tmin, let tmax = day.tmax {
                        Text("\(Int(tmin.rounded()))° / \(Int(tmax.rounded()))°")
                            .font(.subheadline)
                            .monospacedDigit()
                    }
                }
            }
        }
    }

    private var footer: some View {
        VStack(spacing: 6) {
            Divider()
            HStack {
                Button {
                    Task { await viewModel.refresh() }
                } label: {
                    Label("Rafraîchir", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
                if let lastUpdate = viewModel.lastUpdate {
                    Text("MAJ à \(lastUpdate, style: .time)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape")
                }
                .buttonStyle(.borderless)
                .help("Réglages")
                Button(role: .destructive) {
                    NSApplication.shared.terminate(nil)
                } label: {
                    Image(systemName: "power")
                }
                .buttonStyle(.borderless)
                .help("Quitter Météo 7 Jours")
            }
        }
    }

    private func dayLabel(for day: DailyForecast) -> String {
        guard let index = day.day else { return "" }
        if index == 0 { return "Aujourd'hui" }
        if index == 1 { return "Demain" }
        let date = Date().addingTimeInterval(TimeInterval(index) * 86_400)
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date).capitalized
    }
}
