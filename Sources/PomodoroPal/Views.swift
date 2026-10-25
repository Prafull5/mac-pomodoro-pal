import SwiftUI

private let ink = Color(red: 0.18, green: 0.15, blue: 0.25)
private let lavender = Color(red: 0.92, green: 0.86, blue: 1.0)

struct AvatarView: View {
    let avatar: PalAvatar
    let progress: Double
    let size: CGFloat
    var animated = true

    @State private var bob = false

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.55))
                .frame(width: size * 0.88, height: size * 0.88)
                .blur(radius: size * 0.08)

            artwork
                .saturation(0)
                .opacity(0.3)

            artwork
                .mask {
                    GeometryReader { geometry in
                        VStack(spacing: 0) {
                            Spacer(minLength: 0)
                            Rectangle()
                                .frame(height: geometry.size.height * min(1, max(0, progress)))
                        }
                    }
                }
        }
        .frame(width: size, height: size)
        .offset(y: animated && bob ? -5 : 3)
        .rotationEffect(.degrees(animated && bob ? -4 : 4))
        .animation(animated ? .easeInOut(duration: 1.3).repeatForever(autoreverses: true) : nil, value: bob)
        .onAppear { bob = true }
    }

    @ViewBuilder private var artwork: some View {
        if avatar == .pokeball {
            PokeballView()
                .frame(width: size * 0.8, height: size * 0.8)
        } else {
            Text(avatar.emoji)
                .font(.system(size: size * 0.72))
                .frame(width: size, height: size)
        }
    }
}

private struct PokeballView: View {
    var body: some View {
        GeometryReader { geometry in
            let diameter = min(geometry.size.width, geometry.size.height)
            ZStack {
                Circle().fill(.white)
                Circle()
                    .fill(Color(red: 0.98, green: 0.27, blue: 0.34))
                    .mask(alignment: .top) {
                        Rectangle().frame(height: diameter / 2)
                    }
                Rectangle()
                    .fill(ink)
                    .frame(height: diameter * 0.12)
                Circle().fill(ink).frame(width: diameter * 0.34)
                Circle().fill(.white).frame(width: diameter * 0.23)
                Circle().stroke(ink, lineWidth: diameter * 0.06)
            }
            .clipShape(Circle())
            .overlay(Circle().stroke(ink, lineWidth: diameter * 0.055))
        }
    }
}

struct DashboardView: View {
    @ObservedObject var timer: TimerStore

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 1, green: 0.96, blue: 0.94), lavender], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack(spacing: 17) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("pomodoro pal")
                            .font(.system(size: 28, weight: .heavy, design: .rounded))
                        Text("A little company while you get things done.")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("✦  \(timer.completedFocusSessions) finished")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.white.opacity(0.7), in: Capsule())
                }

                VStack(spacing: 8) {
                    AvatarView(avatar: timer.avatar, progress: timer.phase == .ready ? 1 : timer.progress, size: 146)
                    Text(timer.phase.title)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                    Text(timer.timeString)
                        .font(.system(size: 42, weight: .heavy, design: .rounded).monospacedDigit())
                    Text(timer.phase == .focus ? "Your pal fills with color as you focus." : timer.phase == .breakTime ? "Take a breath. You earned it!" : "25 minutes of focus • 10 minutes to recharge")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(.white.opacity(0.65), in: RoundedRectangle(cornerRadius: 26))

                VStack(alignment: .leading, spacing: 10) {
                    Text("CHOOSE YOUR SIDEKICK")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .tracking(1.5)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 7) {
                        ForEach(PalAvatar.allCases) { choice in
                            Button {
                                timer.avatar = choice
                            } label: {
                                VStack(spacing: 3) {
                                    AvatarView(avatar: choice, progress: 1, size: 48, animated: false)
                                    Text(choice.name)
                                        .font(.system(size: 10, weight: .semibold))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(timer.avatar == choice ? .white : .white.opacity(0.35), in: RoundedRectangle(cornerRadius: 15))
                                .overlay(RoundedRectangle(cornerRadius: 15).stroke(timer.avatar == choice ? ink.opacity(0.65) : .clear, lineWidth: 1.5))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Choose \(choice.name)")
                        }
                    }
                }

                HStack(spacing: 10) {
                    if timer.phase == .focus || timer.phase == .breakTime {
                        Button(timer.isPaused ? "▶  Resume" : "Ⅱ  Pause") { timer.togglePause() }
                            .buttonStyle(PalButtonStyle(primary: true))
                        Button("↺  Reset") { timer.reset() }
                            .buttonStyle(PalButtonStyle(primary: false))
                    } else {
                        Button(timer.phase == .breakFinished ? "▶  Start next focus" : "▶  Start focus") { timer.startFocus() }
                            .buttonStyle(PalButtonStyle(primary: true))
                    }
                }
                if timer.phase == .breakTime {
                    Button("Skip break") { timer.skipBreak() }
                        .buttonStyle(.plain)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
            .foregroundStyle(ink)
            .padding(24)
        }
        .frame(width: 460, height: 650)
    }
}

private struct PalButtonStyle: ButtonStyle {
    let primary: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .bold, design: .rounded))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .foregroundStyle(primary ? .white : ink)
            .background(primary ? ink : .white.opacity(0.75), in: RoundedRectangle(cornerRadius: 14))
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

struct FloatingView: View {
    @ObservedObject var timer: TimerStore
    let openDashboard: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    private var cardColor: Color {
        colorScheme == .dark ? Color(red: 0.12, green: 0.11, blue: 0.16) : .white
    }

    private var timerColor: Color {
        colorScheme == .dark ? .white : Color(red: 0.09, green: 0.08, blue: 0.13)
    }

    var body: some View {
        Button(action: openDashboard) {
            HStack(spacing: 6) {
                AvatarView(avatar: timer.avatar, progress: timer.phase == .ready ? 1 : timer.progress, size: 65)
                VStack(alignment: .leading, spacing: 2) {
                    Text(timer.phase == .focus ? "FOCUS" : timer.phase == .breakTime ? "BREAK" : "YOUR PAL")
                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                        .tracking(1.4)
                    Text(timer.phase == .ready || timer.phase == .breakFinished ? "Let's go!" : timer.timeString)
                        .font(.system(size: 20, weight: .heavy, design: .rounded).monospacedDigit())
                }
                Spacer(minLength: 4)
            }
            .foregroundStyle(timerColor)
            .padding(.horizontal, 10)
            .frame(width: 175, height: 79)
            .background(cardColor.opacity(0.96), in: RoundedRectangle(cornerRadius: 22))
            .overlay(RoundedRectangle(cornerRadius: 22).stroke(timerColor.opacity(0.16), lineWidth: 1))
            .shadow(color: .black.opacity(0.28), radius: 12, y: 5)
        }
        .buttonStyle(.plain)
        .help("Open Pomodoro Pal • drag to move")
    }
}

struct OverlayView: View {
    @ObservedObject var timer: TimerStore
    let openDashboard: () -> Void
    @State private var party = false

    private var celebrating: Bool { timer.overlay == .celebration }

    var body: some View {
        ZStack {
            LinearGradient(colors: celebrating ? [Color(red: 1, green: 0.88, blue: 0.76), lavender] : [lavender, Color(red: 0.8, green: 0.95, blue: 0.96)], startPoint: .topLeading, endPoint: .bottomTrailing)
            if celebrating {
                ForEach(0..<30, id: \.self) { index in
                    ConfettiPiece(index: index, party: party)
                }
            }
            VStack(spacing: 14) {
                Text(celebrating ? "🎉  YOU DID IT!  🎉" : "☀️  BREAK'S OVER!")
                    .font(.system(size: 21, weight: .heavy, design: .rounded))
                AvatarView(avatar: timer.avatar, progress: 1, size: 190)
                Text(celebrating ? "25 minutes of focus. Look at you go!" : "Your pal is ready for another stretch.")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                Text(celebrating ? "Your 10-minute break has started." : "Take the next 25 minutes together.")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                Button(celebrating ? "Enjoy my break" : "Start next focus") {
                    if celebrating {
                        timer.dismissOverlay()
                    } else {
                        timer.startFocus()
                        openDashboard()
                    }
                }
                .buttonStyle(PalButtonStyle(primary: true))
                .frame(width: 210)
                if !celebrating {
                    Button("Maybe in a moment") { timer.dismissOverlay() }
                        .buttonStyle(.plain)
                        .font(.system(size: 12))
                }
            }
            .foregroundStyle(ink)
            .padding(28)
        }
        .frame(width: 450, height: 470)
        .clipShape(RoundedRectangle(cornerRadius: 30))
        .onAppear { party = true }
        .onChange(of: timer.overlay) { _, _ in
            party = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { party = true }
        }
    }
}

private struct ConfettiPiece: View {
    let index: Int
    let party: Bool

    private var seed: Double { Double((index * 67 + 13) % 101) / 101 }

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill([Color.pink, .orange, .purple, .mint, .yellow][index % 5])
            .frame(width: 7, height: 14)
            .rotationEffect(.degrees(party ? Double(index * 97) : 0))
            .offset(x: party ? (seed - 0.5) * 440 : 0,
                    y: party ? Double((index * 41) % 101 - 50) * 4.7 : -25)
            .opacity(party ? 0 : 1)
            .animation(.easeOut(duration: 2.5).delay(Double(index % 7) * 0.035), value: party)
    }
}
