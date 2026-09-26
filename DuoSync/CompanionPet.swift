import SwiftUI
import UIKit

enum CompanionSpecies: String, CaseIterable, Identifiable {
    case corgi, capybara, cat, bunny, paperclip, disc, snake

    var id: String { rawValue }
    static let animals: [CompanionSpecies] = [.corgi, .capybara, .cat, .bunny]
    static let retro: [CompanionSpecies] = [.paperclip, .disc, .snake]
    var title: String {
        switch self {
        case .paperclip: return "Pixel Clip"
        case .disc: return "Bouncy Disc"
        case .snake: return "Pocket Snake"
        default: return rawValue.capitalized
        }
    }
    var symbol: String {
        switch self {
        case .corgi: return "🐶"
        case .capybara: return "🦫"
        case .cat: return "🐱"
        case .bunny: return "🐰"
        case .paperclip: return "📎"
        case .disc: return "💿"
        case .snake: return "🐍"
        }
    }
    var assetName: String { Self.retro.contains(self) ? "NostalgiaRoster" : "PetRoster" }
    var spriteOffset: CGSize {
        switch self {
        case .corgi, .paperclip: return CGSize(width: 34, height: 34)
        case .capybara, .disc: return CGSize(width: -34, height: 34)
        case .cat, .snake: return CGSize(width: 34, height: -34)
        case .bunny: return CGSize(width: -34, height: -34)
        }
    }
    var hopSpeed: Double {
        switch self {
        case .corgi: return 2.2
        case .capybara: return 1.0
        case .cat: return 1.5
        case .bunny: return 2.8
        case .paperclip: return 1.9
        case .disc: return 2.5
        case .snake: return 1.3
        }
    }
    var hopHeight: Double {
        switch self {
        case .corgi: return 3
        case .capybara: return 2
        case .cat: return 3
        case .bunny: return 5
        case .paperclip: return 3
        case .disc: return 4
        case .snake: return 2
        }
    }
}

/// A single companion with small, local animation cues; no model activity is implied.
struct CompanionPet: View {
    enum Activity: Equatable {
        case idle, capturing, ready
    }

    let activity: Activity
    let workspaceOpen: Bool
    let species: CompanionSpecies
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var readyAt = Date.distantPast

    private var motionAllowed: Bool { !reduceMotion && scenePhase == .active }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !motionAllowed)) { timeline in
            // Pixel artwork stays crisp while the companion moves gently.
            let t = timeline.date.timeIntervalSinceReferenceDate
            let readyElapsed = timeline.date.timeIntervalSince(readyAt)
            let bob = motionAllowed && activity == .idle
                ? -max(0, sin(t * species.hopSpeed)) * species.hopHeight : 0
            // One soft lift and return when a result becomes ready.
            let bounce = motionAllowed && activity == .ready && readyElapsed >= 0 && readyElapsed < 0.8
                ? -9 * sin(.pi * readyElapsed / 0.8) : 0
            let tilt = motionAllowed && activity == .idle ? sin(t * 1.3) * 2 : 0
            let workingWiggle = motionAllowed && activity == .capturing ? sin(t * 4) * 1.5 : 0
            let wander = motionAllowed && activity == .idle && (species == .disc || species == .snake)
                ? sin(t * species.hopSpeed) * (species == .disc ? 5 : 3) : 0
            ZStack {
                artwork
                if motionAllowed && activity == .ready && readyElapsed >= 0 && readyElapsed < 1.0 {
                    Text("✦")
                        .font(.system(size: 17, weight: .black, design: .monospaced))
                        .foregroundStyle(.yellow)
                        .offset(x: 27, y: -29)
                        .accessibilityHidden(true)
                }
            }
                .rotationEffect(.degrees(tilt))
                .offset(x: workingWiggle + wander, y: bob + bounce)
        }
        .frame(width: 68, height: 68)
        .onChange(of: activity) { _, newValue in
            if newValue == .ready { readyAt = Date() }
        }
    }

    @ViewBuilder
    private var artwork: some View {
        if UIImage(named: species.assetName) != nil {
            Image(species.assetName)
                .resizable()
                .interpolation(.none)
                .frame(width: 136, height: 136)
                .offset(species.spriteOffset)
                .frame(width: 68, height: 68)
                .clipped()
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
