import SwiftUI
import WebKit

@MainActor
final class BrowserStore: NSObject, ObservableObject, WKNavigationDelegate {
    let webView = WKWebView()
    @Published var address = ""
    @Published var errorMessage: String?
    @Published private(set) var context: PageContext?
    @Published private(set) var explanation: Explanation?
    @Published private(set) var isCapturing = false

    private var documentID = UUID()
    private var captureID = UUID()
    private var documentReady = false
    private var captureTimeout: DispatchWorkItem?
    private var bundledURL: URL? { Bundle.main.url(forResource: "Reading", withExtension: "html") }

    override init() {
        super.init()
        webView.navigationDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        loadDemo()
    }

    func loadDemo() {
        guard let url = bundledURL else {
            errorMessage = "The bundled reading page is missing."
            return
        }
        invalidateDocument()
        address = ""
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
        invalidateDocument()
        webView.load(URLRequest(url: url))
    }

    /// Called only in response to a user action. No passive capture or model request.
    func exploreSelection() {
        cancelCapture()
        context = nil
        explanation = nil
        errorMessage = nil
        guard documentReady, !webView.isLoading, let sourceURL = webView.url else {
            errorMessage = "Wait for the page to finish loading, then select a sentence and try again."
            return
        }
        let requestedDocument = documentID
        let requestID = captureID
        isCapturing = true
        let timeout = DispatchWorkItem { [weak self] in
            guard let self, self.captureID == requestID else { return }
            self.cancelCapture()
            self.errorMessage = "Reading the selection timed out. Select a sentence and try again."
        }
        captureTimeout = timeout
        DispatchQueue.main.asyncAfter(deadline: .now() + 8, execute: timeout)

        // nil frame targets the main frame; an isolated world avoids page-defined JS globals.
        // Only the bounded source and current selection cross into native code.
        let script = """
        (() => {
            const text = document.body ? document.body.innerText : '';
            const selection = window.getSelection()?.toString() || '';
            return {url: location.href, title: document.title.slice(0, 300),
                    text: text.slice(0, 12000), selection: selection.slice(0, 4001),
                    truncated: text.length > 12000};
        })()
        """
        webView.evaluateJavaScript(script, in: nil, in: .defaultClient) { [weak self] result in
            guard let self, self.captureID == requestID,
                  self.documentID == requestedDocument else { return }
            self.cancelCapture()
            guard self.documentReady, !self.webView.isLoading, self.webView.url == sourceURL else {
                self.errorMessage = ContextValidation.Failure.invalidSource.localizedDescription
                return
            }
            do {
                let value = try result.get()
                guard let payload = value as? [String: Any],
                      let url = payload["url"] as? String,
                      let title = payload["title"] as? String,
                      let text = payload["text"] as? String,
                      let selection = payload["selection"] as? String,
                      let truncated = payload["truncated"] as? Bool else {
                    throw ContextValidation.Failure.invalidSource
                }
                let captured = try ContextValidation.context(documentID: requestedDocument,
                    expectedURL: sourceURL, reportedURL: url, title: title, text: text, selection: selection)
                self.context = captured
                self.explanation = ContextValidation.bundledExplanation(for: captured, bundledURL: self.bundledURL)
                if self.explanation == nil {
                    self.errorMessage = "Selection captured. Live reasoning isn't connected; open the bundled lesson to try its prewritten explanation."
                }
                if truncated {
                    self.errorMessage = (self.errorMessage.map { $0 + " " } ?? "")
                        + "Page capture was limited to the first 12,000 characters."
                }
            } catch let failure as ContextValidation.Failure {
                self.errorMessage = failure.localizedDescription
            } catch {
                self.errorMessage = "Couldn't read this page's selection. Try selecting text again, or open the bundled lesson."
            }
        }
    }

    func clearExplanation() {
        cancelCapture()
        explanation = nil
        errorMessage = nil
    }

    private func cancelCapture() {
        captureID = UUID()
        captureTimeout?.cancel()
        captureTimeout = nil
        isCapturing = false
    }

    private func invalidateDocument() {
        cancelCapture()
        documentID = UUID()
        documentReady = false
        context = nil
        explanation = nil
        errorMessage = nil
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url,
              ["https", "http"].contains(url.scheme?.lowercased() ?? "") || url == bundledURL else {
            decisionHandler(.cancel)
            errorMessage = "This demo supports web pages and its bundled reading lesson."
            return
        }
        // No popup web views: all captured context must come from our one owned main frame.
        guard navigationAction.targetFrame != nil else {
            decisionHandler(.cancel)
            errorMessage = "This link opens a new window. Enter its web address above to read it here."
            return
        }
        if navigationAction.targetFrame?.isMainFrame == true {
            invalidateDocument()
        }
        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        invalidateDocument()
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        documentReady = true
        address = webView.url?.isFileURL == true ? "" : (webView.url?.absoluteString ?? "")
        errorMessage = nil
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        show(error)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        show(error)
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        invalidateDocument()
        errorMessage = "The page stopped responding. Open the bundled demo or reload its web address."
    }

    private func show(_ error: Error) {
        guard (error as NSError).code != NSURLErrorCancelled else { return }
        invalidateDocument()
        errorMessage = "Couldn't load this page. Try again or open the bundled demo."
    }
}

struct BrowserView: UIViewRepresentable {
    let store: BrowserStore
    func makeUIView(context: Context) -> WKWebView { store.webView }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
