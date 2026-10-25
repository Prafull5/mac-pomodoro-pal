import Foundation
import Combine

enum TimerPhase: String {
    case ready, focus, breakTime, breakFinished

    var title: String {
        switch self {
        case .ready: return "Ready to focus"
        case .focus: return "Focus time"
        case .breakTime: return "Break time"
        case .breakFinished: return "Ready for another stretch?"
        }
    }
}

enum PalAvatar: String, CaseIterable, Identifiable {
    case peach, football, pokeball, dumpling, frog

    var id: String { rawValue }

    var name: String {
        switch self {
        case .peach: return "Peach"
        case .football: return "Football"
        case .pokeball: return "Poké Ball"
        case .dumpling: return "Dumpling"
        case .frog: return "Frog"
        }
    }

    var emoji: String {
        switch self {
        case .peach: return "🍑"
        case .football: return "⚽️"
        case .pokeball: return "🔴"
        case .dumpling: return "🥟"
        case .frog: return "🐸"
        }
    }
}

@MainActor
final class TimerStore: ObservableObject {
    @Published var avatar: PalAvatar = .peach {
        didSet { UserDefaults.standard.set(avatar.rawValue, forKey: "avatar") }
    }
    @Published private(set) var phase: TimerPhase = .ready
    @Published private(set) var isPaused = false
    @Published private(set) var secondsRemaining: TimeInterval = 25 * 60
    @Published private(set) var completedFocusSessions = 0
    @Published var overlay: OverlayKind?

    let focusDuration: TimeInterval = 25 * 60
    let breakDuration: TimeInterval = 10 * 60
    private var deadline: Date?
    private var ticker: AnyCancellable?

    enum OverlayKind { case celebration, breakFinished }

    init() {
        if let saved = UserDefaults.standard.string(forKey: "avatar"),
           let choice = PalAvatar(rawValue: saved) { avatar = choice }
        ticker = Timer.publish(every: 0.25, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.tick() }
    }

    var totalDuration: TimeInterval {
        phase == .breakTime ? breakDuration : focusDuration
    }

    var progress: Double {
        switch phase {
        case .ready: return 0
        case .focus, .breakTime: return min(1, max(0, 1 - secondsRemaining / totalDuration))
        case .breakFinished: return 1
        }
    }

    var timeString: String {
        let wholeSeconds = Int(ceil(secondsRemaining))
        return String(format: "%02d:%02d", wholeSeconds / 60, wholeSeconds % 60)
    }

    func startFocus() {
        overlay = nil
        phase = .focus
        isPaused = false
        secondsRemaining = focusDuration
        deadline = Date().addingTimeInterval(focusDuration)
    }

    func togglePause() {
        guard phase == .focus || phase == .breakTime else { return }
        if isPaused {
            isPaused = false
            deadline = Date().addingTimeInterval(secondsRemaining)
        } else {
            tick()
            isPaused = true
            deadline = nil
        }
    }

    func reset() {
        overlay = nil
        phase = .ready
        isPaused = false
        deadline = nil
        secondsRemaining = focusDuration
    }

    func skipBreak() {
        guard phase == .breakTime else { return }
        phase = .breakFinished
        isPaused = false
        deadline = nil
        secondsRemaining = 0
        overlay = .breakFinished
    }

    func dismissOverlay() { overlay = nil }

    private func tick() {
        guard !isPaused, let deadline else { return }
        let remaining = deadline.timeIntervalSinceNow
        if remaining > 0 {
            secondsRemaining = remaining
            return
        }

        if phase == .focus {
            completedFocusSessions += 1
            phase = .breakTime
            secondsRemaining = max(0, breakDuration + remaining)
            self.deadline = Date().addingTimeInterval(secondsRemaining)
            overlay = .celebration
            if secondsRemaining <= 0 { tick() }
        } else if phase == .breakTime {
            phase = .breakFinished
            secondsRemaining = 0
            self.deadline = nil
            overlay = .breakFinished
        }
    }
}
