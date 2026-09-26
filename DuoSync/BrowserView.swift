import SwiftUI
import WebKit

@MainActor
final class BrowserStore: NSObject, ObservableObject, WKNavigationDelegate {
    let webView = WKWebView()
    @Published var address = ""
    @Published var errorMessage: String?

    override init() {
        super.init()
        webView.navigationDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        loadDemo()
    }

    func loadDemo() {
        guard let url = Bundle.main.url(forResource: "Reading", withExtension: "html") else {
            errorMessage = "The bundled reading page is missing."
            return
        }
        address = ""
        errorMessage = nil
        webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
    }

    func navigate() {
        let input = address.trimmingCharacters(in: .whitespacesAndNewlines)
        let candidate = input.contains("://") ? input : "https://" + input
        guard let url = URL(string: candidate),
              ["https", "http"].contains(url.scheme?.lowercased() ?? ""),
              let host = url.host, !host.isEmpty else {
            errorMessage = "Enter a valid web address, such as https://example.com."
            return
        }
        errorMessage = nil
        webView.load(URLRequest(url: url))
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        address = webView.url?.isFileURL == true ? "" : (webView.url?.absoluteString ?? "")
        errorMessage = nil
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        show(error)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        show(error)
    }

    private func show(_ error: Error) {
        guard (error as NSError).code != NSURLErrorCancelled else { return }
        errorMessage = "Couldn't load this page. Try again or open the bundled demo."
    }
}

struct BrowserView: UIViewRepresentable {
    let store: BrowserStore
    func makeUIView(context: Context) -> WKWebView { store.webView }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
