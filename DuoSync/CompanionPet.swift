import SwiftUI
import UIKit

/// A single companion with small, local animation cues; no model activity is implied.
struct CompanionPet: View {
    enum Activity: Equatable {
        case idle, capturing, ready
    }

    let activity: Activity
    let workspaceOpen: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var readyAt = Date.distantPast

    private var motionAllowed: Bool { !reduceMotion && scenePhase == .active }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !motionAllowed)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let readyElapsed = timeline.date.timeIntervalSince(readyAt)
            let bob = motionAllowed && activity == .idle ? sin(t * 1.4) * 2 : 0
            // One soft lift and return when a result becomes ready.
            let bounce = motionAllowed && activity == .ready && readyElapsed >= 0 && readyElapsed < 0.8
                ? -6 * sin(.pi * readyElapsed / 0.8) : 0
            let tilt = motionAllowed && activity == .idle ? sin(t * 0.9) * 2 : 0
            let pulse = motionAllowed && activity == .capturing ? 1 + 0.025 * sin(t * 3) : 1
            artwork
                .scaleEffect(pulse)
                .rotationEffect(.degrees(tilt))
                .offset(y: bob + bounce)
        }
        .frame(width: 68, height: 68)
        .onChange(of: activity) { _, newValue in
            if newValue == .ready { readyAt = Date() }
        }
    }

    @ViewBuilder
    private var artwork: some View {
        if UIImage(named: "CompanionPet") != nil {
            Image("CompanionPet")
                .resizable()
                .scaledToFit()
                .frame(width: 68, height: 68)
                .shadow(color: .black.opacity(0.16), radius: 6, y: 4)
        } else {
            VStack(spacing: 5) {
                HStack(spacing: 9) {
                    Capsule().frame(width: 5, height: workspaceOpen ? 5 : 10)
                    Capsule().frame(width: 5, height: workspaceOpen ? 5 : 10)
                }
                Capsule().frame(width: 13, height: 3)
            }
            .foregroundStyle(Color(red: 0.06, green: 0.19, blue: 0.15))
            .frame(width: 62, height: 62)
            .background(Color(red: 0.48, green: 0.91, blue: 0.74), in: RoundedRectangle(cornerRadius: 24))
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(.white.opacity(0.7), lineWidth: 2))
            .shadow(color: .black.opacity(0.15), radius: 10, y: 5)
        }
    }
}
