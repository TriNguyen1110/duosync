import SwiftUI

struct PendulumView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var length = 1.0
    @State private var playing = true
    @State private var epoch = Date()

    private var period: Double { 2 * .pi * sqrt(length / 9.81) }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Try the idea", systemImage: "hand.draw")
                    .font(.headline)
                Spacer()
                Button {
                    epoch = Date()
                    playing.toggle()
                } label: {
                    Image(systemName: playing ? "pause.circle.fill" : "play.circle.fill")
                        .font(.title2)
                }
                .accessibilityLabel(playing ? "Pause pendulum" : "Play pendulum")
                .disabled(reduceMotion)
            }
            TimelineView(.animation(paused: !playing || reduceMotion)) { timeline in
                let elapsed = timeline.date.timeIntervalSince(epoch)
                let angle = playing && !reduceMotion ? 0.18 * cos(2 * .pi * elapsed / period) : 0
                GeometryReader { geometry in
                    let pivot = CGPoint(x: geometry.size.width / 2, y: 16)
                    let radius = CGFloat(65 + length * 43)
                    let bob = CGPoint(x: pivot.x + radius * CGFloat(sin(angle)), y: pivot.y + radius * CGFloat(cos(angle)))
                    Path { path in
                        path.move(to: CGPoint(x: pivot.x - 30, y: pivot.y))
                        path.addLine(to: CGPoint(x: pivot.x + 30, y: pivot.y))
                    }
                    .stroke(Color.secondary.opacity(0.4), style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    Path { path in
                        path.move(to: pivot)
                        path.addLine(to: bob)
                    }
                    .stroke(Color.primary.opacity(0.7), lineWidth: 2)
                    Circle().fill(Color.accentColor)
                        .frame(width: 30, height: 30)
                        .shadow(color: .black.opacity(0.12), radius: 8, y: 5)
                        .position(bob)
                }
            }
            .frame(height: 190)
            .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 18))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Pendulum visualization")
            .accessibilityValue("Length \(length.formatted(.number.precision(.fractionLength(2)))) meters, period \(period.formatted(.number.precision(.fractionLength(2)))) seconds")

            HStack(alignment: .firstTextBaseline) {
                Text("Length").foregroundStyle(.secondary)
                Spacer()
                Text("\(length, specifier: "%.2f") m").monospacedDigit().bold()
            }
            Slider(value: $length, in: 0.2...2.0, step: 0.05)
                .accessibilityLabel("Pendulum length")
                .accessibilityValue("\(length.formatted(.number.precision(.fractionLength(2)))) meters")
            HStack(alignment: .firstTextBaseline) {
                Text("One full swing").foregroundStyle(.secondary)
                Spacer()
                Text("\(period, specifier: "%.2f") s")
                    .font(.title2.bold()).monospacedDigit()
            }
            Text("Longer string, slower swing. Double the length and the period grows by √2.")
                .font(.subheadline)
            Text("T = 2π√(L/g) · g = 9.81 m/s²\nSmall-angle approximation; ideal string, no friction. Calculated on your device.")
                .font(.caption).foregroundStyle(.secondary)
        }
        .padding(18)
        .background(Color.accentColor.opacity(0.07), in: RoundedRectangle(cornerRadius: 22))
    }
}
