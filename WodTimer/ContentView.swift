import SwiftUI

struct ContentView: View {
    @StateObject private var model = TimerModel()
    @State private var showConfig = false

    var body: some View {
        ZStack {
            backgroundGradient
            VStack(spacing: 0) {
                header
                Spacer()
                timerDisplay
                Spacer()
                phaseLabel
                Spacer()
                controls
                    .padding(.bottom, 40)
            }
        }
        .sheet(isPresented: $showConfig) {
            ConfigView(model: model)
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Background

    var backgroundGradient: some View {
        let colors: [Color] = {
            switch model.phase {
            case .work:    return [Color(hex: "1a1a2e"), Color(hex: "16213e")]
            case .rest:    return [Color(hex: "0f3460"), Color(hex: "0a1931")]
            case .countdown: return [Color(hex: "2d1b00"), Color(hex: "1a1000")]
            case .finished: return [Color(hex: "003300"), Color(hex: "001a00")]
            default:       return [Color(hex: "0d0d0d"), Color(hex: "1a1a1a")]
            }
        }()
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.5), value: model.phase)
    }

    // MARK: - Header

    var header: some View {
        HStack {
            Text("WOD Timer")
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundColor(.white)
            Spacer()
            if model.phase == .idle {
                Button { showConfig = true } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
    }

    // MARK: - Timer Display

    var timerDisplay: some View {
        VStack(spacing: 12) {
            if model.phase == .finished {
                Text("TIME!")
                    .font(.system(size: 80, weight: .black, design: .rounded))
                    .foregroundColor(.green)
                    .transition(.scale)
            } else {
                Text(model.phase == .idle ? modePreviewTime : model.formattedTime)
                    .font(.system(size: 90, weight: .black, design: .monospaced))
                    .foregroundColor(.white)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .animation(.linear(duration: 0.15), value: model.displayTime)

                if model.totalRounds > 0 {
                    Text("Round \(model.currentRound) / \(model.totalRounds)")
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
    }

    var modePreviewTime: String {
        switch model.mode {
        case .amrap, .forTime, .countdown:
            let s = model.totalMinutes * 60
            return String(format: "%02d:%02d", s / 60, s % 60)
        case .emom:
            return "01:00"
        case .tabata:
            return String(format: "%02d:%02d", model.workSeconds / 60, model.workSeconds % 60)
        }
    }

    // MARK: - Phase Label

    var phaseLabel: some View {
        VStack(spacing: 6) {
            Text(model.mode.rawValue)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.5))
                .textCase(.uppercase)
                .tracking(4)

            Text(phaseName)
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(phaseTextColor)
                .animation(.easeInOut(duration: 0.3), value: model.phase)
        }
    }

    var phaseName: String {
        switch model.phase {
        case .idle:      return "Ready"
        case .countdown: return "Get Ready"
        case .work:      return "Work"
        case .rest:      return "Rest"
        case .finished:  return "Complete"
        }
    }

    var phaseTextColor: Color {
        switch model.phase {
        case .work:      return Color(hex: "ff6b35")
        case .rest:      return Color(hex: "4ecdc4")
        case .countdown: return Color(hex: "ffd700")
        case .finished:  return .green
        default:         return .white
        }
    }

    // MARK: - Controls

    var controls: some View {
        HStack(spacing: 24) {
            if model.phase == .idle || model.phase == .finished {
                Button(action: { withAnimation { model.start() } }) {
                    Label("Start", systemImage: "play.fill")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color(hex: "ff6b35"))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            } else {
                Button(action: {
                    if model.isRunning { model.pause() } else { model.resume() }
                }) {
                    Label(model.isRunning ? "Pause" : "Resume",
                          systemImage: model.isRunning ? "pause.fill" : "play.fill")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color(hex: "4ecdc4"))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                Button(action: { withAnimation { model.reset() } }) {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 60)
                        .padding(.vertical, 18)
                        .background(Color.white.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Config Sheet

struct ConfigView: View {
    @ObservedObject var model: TimerModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section("Mode") {
                    Picker("Mode", selection: $model.mode) {
                        ForEach(WodMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 120)
                }

                switch model.mode {
                case .amrap, .forTime, .countdown:
                    Section("Duration") {
                        Stepper("\(model.totalMinutes) minutes", value: $model.totalMinutes, in: 1...60)
                    }
                case .emom:
                    Section("Rounds") {
                        Stepper("\(model.rounds) rounds", value: $model.rounds, in: 1...60)
                    }
                case .tabata:
                    Section("Tabata") {
                        Stepper("Work: \(model.workSeconds)s", value: $model.workSeconds, in: 5...120, step: 5)
                        Stepper("Rest: \(model.restSeconds)s", value: $model.restSeconds, in: 5...120, step: 5)
                        Stepper("\(model.rounds) rounds", value: $model.rounds, in: 1...30)
                    }
                }

                Section("Countdown") {
                    Stepper("\(model.countdownSeconds)s before start", value: $model.countdownSeconds, in: 3...30)
                }
            }
            .navigationTitle("Configure WOD")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Color extension

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >> 8) & 0xFF) / 255
        let b = Double(rgb & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
