import Foundation
import Combine
import AVFoundation

enum WodMode: String, CaseIterable, Identifiable {
    case amrap = "AMRAP"
    case emom = "EMOM"
    case forTime = "For Time"
    case tabata = "Tabata"
    case countdown = "Countdown"

    var id: String { rawValue }
}

enum TimerPhase {
    case idle, countdown, work, rest, finished
}

class TimerModel: ObservableObject {
    // Config
    @Published var mode: WodMode = .amrap
    @Published var totalMinutes: Int = 10
    @Published var rounds: Int = 5
    @Published var workSeconds: Int = 40
    @Published var restSeconds: Int = 20
    @Published var countdownSeconds: Int = 10

    // State
    @Published var phase: TimerPhase = .idle
    @Published var displayTime: Int = 0
    @Published var currentRound: Int = 1
    @Published var totalRounds: Int = 0
    @Published var isRunning: Bool = false

    private var timer: AnyCancellable?
    private var audioPlayer: AVAudioPlayer?
    private var beepSynth = BeepSynth()

    // MARK: - Controls

    func start() {
        switch mode {
        case .amrap, .forTime, .countdown:
            totalRounds = 0
            currentRound = 1
            phase = .countdown
            displayTime = countdownSeconds
        case .emom:
            totalRounds = rounds
            currentRound = 1
            phase = .countdown
            displayTime = countdownSeconds
        case .tabata:
            totalRounds = rounds
            currentRound = 1
            phase = .countdown
            displayTime = countdownSeconds
        }
        isRunning = true
        startTick()
    }

    func pause() {
        isRunning = false
        timer?.cancel()
    }

    func resume() {
        isRunning = true
        startTick()
    }

    func reset() {
        timer?.cancel()
        isRunning = false
        phase = .idle
        displayTime = 0
        currentRound = 1
        totalRounds = 0
    }

    // MARK: - Tick

    private func startTick() {
        timer?.cancel()
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.tick() }
    }

    private func tick() {
        guard displayTime > 0 else {
            advancePhase()
            return
        }
        displayTime -= 1
        if displayTime <= 3 && displayTime > 0 {
            beepSynth.beep(frequency: 880, duration: 0.1)
        }
    }

    private func advancePhase() {
        switch phase {
        case .countdown:
            enterWork()

        case .work:
            switch mode {
            case .tabata:
                if currentRound >= totalRounds {
                    finish()
                } else {
                    enterRest()
                }
            case .emom:
                if currentRound >= totalRounds {
                    finish()
                } else {
                    currentRound += 1
                    enterWork()
                }
            default:
                finish()
            }

        case .rest:
            currentRound += 1
            enterWork()

        default:
            break
        }
    }

    private func enterWork() {
        phase = .work
        beepSynth.beep(frequency: 1200, duration: 0.3)
        switch mode {
        case .amrap, .forTime, .countdown:
            displayTime = totalMinutes * 60
        case .emom:
            displayTime = 60
        case .tabata:
            displayTime = workSeconds
        }
    }

    private func enterRest() {
        phase = .rest
        beepSynth.beep(frequency: 600, duration: 0.3)
        displayTime = restSeconds
    }

    private func finish() {
        phase = .finished
        isRunning = false
        timer?.cancel()
        beepSynth.beep(frequency: 1200, duration: 0.15)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { self.beepSynth.beep(frequency: 1200, duration: 0.15) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { self.beepSynth.beep(frequency: 1200, duration: 0.4) }
    }

    // MARK: - Helpers

    var formattedTime: String {
        let m = displayTime / 60
        let s = displayTime % 60
        return String(format: "%02d:%02d", m, s)
    }

    var phaseColor: String {
        switch phase {
        case .work: return "WorkColor"
        case .rest: return "RestColor"
        case .countdown: return "CountdownColor"
        case .finished: return "FinishedColor"
        default: return "IdleColor"
        }
    }
}

// MARK: - Simple beep synthesizer using AVAudioEngine

class BeepSynth {
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()

    init() {
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: nil)
        try? engine.start()
    }

    func beep(frequency: Double, duration: Double) {
        let sampleRate = 44100.0
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(
            pcmFormat: AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!,
            frameCapacity: frameCount
        ) else { return }
        buffer.frameLength = frameCount
        let data = buffer.floatChannelData![0]
        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            let envelope = min(1.0, min(t / 0.01, (duration - t) / 0.01))
            data[i] = Float(sin(2 * .pi * frequency * t) * envelope * 0.5)
        }
        player.scheduleBuffer(buffer, completionHandler: nil)
        if !player.isPlaying { player.play() }
    }
}
