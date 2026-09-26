import SwiftUI

/// The fallback is ordinary adaptive layout; only the gated path uses Duo APIs.
struct DuoLayout<Reader: View, Workspace: View>: View {
    let workspaceOpen: Bool
    let reader: Reader
    let workspace: Workspace

    init(workspaceOpen: Bool, @ViewBuilder reader: () -> Reader,
         @ViewBuilder workspace: () -> Workspace) {
        self.workspaceOpen = workspaceOpen
        self.reader = reader()
        self.workspace = workspace()
    }

    var body: some View {
        GeometryReader { geometry in
            #if DUO_SDK
            if #available(iOS 27.1, *) {
                nativeLayout(wide: geometry.size.width >= 700)
            } else {
                fallback(wide: geometry.size.width >= 700)
            }
            #else
            fallback(wide: geometry.size.width >= 700)
            #endif
        }
    }

    #if DUO_SDK
    @available(iOS 27.1, *)
    @ViewBuilder
    private func nativeLayout(wide: Bool) -> some View {
        // Both axes remain enabled: the system can respond to active division regions.
        if wide {
            ArrangementView {
                reader
            } secondary: {
                if workspaceOpen { workspace }
            }
            .arrangementViewStyle(.split)
        } else {
            // Apple's overlay arrangement places its primary view in the foreground.
            // A horizontal-only split may hide the assistant on a portrait display.
            ArrangementView {
                if workspaceOpen { workspace.padding(8) }
            } secondary: {
                reader
            }
            .arrangementViewStyle(.overlay)
        }
    }
    #endif

    @ViewBuilder
    private func fallback(wide: Bool) -> some View {
        if wide {
            HStack(spacing: 12) {
                reader
                if workspaceOpen { workspace.frame(maxWidth: 430) }
            }
        } else {
            ZStack {
                reader
                if workspaceOpen { workspace.padding(8) }
            }
        }
    }
}
