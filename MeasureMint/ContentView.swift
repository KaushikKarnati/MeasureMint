import SwiftUI

// MARK: - Model
struct ConversionRecord: Identifiable {
    let id = UUID()
    let input: String
    let output: String
    let type: String
    let timestamp: Date
}

// MARK: - Main View
struct ContentView: View {
    enum ConversionType: String, CaseIterable {
        case length = "📏 Length"
        case temperature = "🌡️ Temperature"
    }

    let lengthUnits: [UnitLength] = [.meters, .kilometers, .feet, .yards, .miles]
    let temperatureUnits: [UnitTemperature] = [.celsius, .fahrenheit]

    @State private var conversionType: ConversionType = .length
    @State private var inputUnit: Dimension = UnitLength.meters
    @State private var outputUnit: Dimension = UnitLength.feet
    @State private var inputValue = 0.0
    @State private var convertedText: String = ""
    @State private var history: [ConversionRecord] = []

    @FocusState private var isFocused: Bool
    @State private var showHistory = false

    var availableUnits: [Dimension] {
        switch conversionType {
        case .length: return lengthUnits
        case .temperature: return temperatureUnits
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    sectionCard {
                        Text("🧭 Conversion Type")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Picker("", selection: $conversionType) {
                            ForEach(ConversionType.allCases, id: \.self) {
                                Text($0.rawValue)
                            }
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: conversionType) { _ in
                            inputUnit = availableUnits.first ?? UnitLength.meters
                            outputUnit = availableUnits.last ?? UnitLength.kilometers
                            convertedText = ""
                        }
                    }

                    sectionCard {
                        Text("🔢 Enter Value")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        TextField("Value", value: $inputValue, format: .number)
                            .keyboardType(.decimalPad)
                            .focused($isFocused)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }

                    sectionCard {
                        Text("📥 From Unit")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Picker("From", selection: $inputUnit) {
                            ForEach(availableUnits, id: \.self) {
                                Text(unitLabel(for: $0))
                            }
                        }
                        .pickerStyle(.navigationLink)
                    }

                    sectionCard {
                        Text("📤 To Unit")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Picker("To", selection: $outputUnit) {
                            ForEach(availableUnits, id: \.self) {
                                Text(unitLabel(for: $0))
                            }
                        }
                        .pickerStyle(.navigationLink)
                    }

                    sectionCard {
                        Button {
                            convertAndSave()
                            isFocused = false
                        } label: {
                            Text("Convert")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.accentColor)
                                .cornerRadius(12)
                        }
                    }

                    if !convertedText.isEmpty {
                        sectionCard {
                            Text("🎯 Converted Value")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Text(convertedText)
                                .font(.title3)
                                .bold()
                                .padding(.top, 4)
                        }
                    }

                    sectionCard {
                        NavigationLink(destination: HistoryView(history: $history)) {
                            Label("View Conversion History", systemImage: "clock.arrow.circlepath")
                                .fontWeight(.medium)
                                .foregroundColor(Color.accentColor)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("MeasureMint")
            .background(Color(.systemGroupedBackground))
            .toolbar {
                if isFocused {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Done") { isFocused = false }
                    }
                }
            }
        }
    }

    func sectionCard<Content: View>(@ViewBuilder content: @escaping () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12, content: content)
            .padding()
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    func unitLabel(for unit: Dimension) -> String {
        switch unit {
        case is UnitLength:
            switch unit as! UnitLength {
            case .meters: return "📏 Meters"
            case .kilometers: return "🌍 Kilometers"
            case .feet: return "👣 Feet"
            case .yards: return "🪢 Yards"
            case .miles: return "🛣️ Miles"
            default: return unit.symbol
            }
        case is UnitTemperature:
            switch unit as! UnitTemperature {
            case .celsius: return "🌡️ Celsius"
            case .fahrenheit: return "🔥 Fahrenheit"
            default: return unit.symbol
            }
        default:
            return unit.symbol
        }
    }

    func convertAndSave() {
        let input = Measurement(value: inputValue, unit: inputUnit)
        let output = input.converted(to: outputUnit)

        let formatter = MeasurementFormatter()
        formatter.unitOptions = .providedUnit
        formatter.unitStyle = .medium

        let inputStr = formatter.string(from: input)
        let outputStr = formatter.string(from: output)
        convertedText = outputStr

        let record = ConversionRecord(
            input: inputStr,
            output: outputStr,
            type: conversionType.rawValue,
            timestamp: Date()
        )

        if history.last?.input != inputStr || history.last?.output != outputStr {
            withAnimation {
                history.append(record)
            }
        }
    }
}

// MARK: - History View (Styled)
struct HistoryView: View {
    @Binding var history: [ConversionRecord]

    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    var body: some View {
        List {
            if history.isEmpty {
                Text("No conversions yet.")
                    .foregroundColor(.gray)
                    .italic()
            } else {
                ForEach(history.reversed()) { record in
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(record.input) → \(record.output)")
                            .font(.headline)
                        Text(record.type)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Text(dateFormatter.string(from: record.timestamp))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Conversion History")
        .toolbar {
            if !history.isEmpty {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Clear") {
                        withAnimation {
                            history.removeAll()
                        }
                    }
                    .foregroundColor(.red)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
