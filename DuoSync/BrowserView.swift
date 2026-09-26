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
    @Published private(set) var isPageLoading = true

    @Published private(set) var messages: [ChatMessage] = []
    @Published private(set) var isResponding = false
    @Published private(set) var chatError: String?

    private var screenConversation = false
    private var responseID = UUID()
    private var responseTask: URLSessionDataTask?
    private var responseTimeout: DispatchWorkItem?
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
            cancelCapture()
            isPageLoading = false
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
        guard !isResponding else { return }
        guard messages.isEmpty else {
            chatError = "Clear this conversation before exploring another demo selection."
            return
        }
        captureSelection(makeBundledExplanation: true) { _ in }
    }

    private func captureSelection(makeBundledExplanation: Bool, completion: @escaping (PageContext?) -> Void) {
        cancelCapture()
        context = nil
        explanation = nil
        errorMessage = nil
        guard documentReady, !webView.isLoading, let sourceURL = webView.url else {
            errorMessage = "Wait for the page to finish loading, then select a sentence and try again."
            completion(nil)
            return
        }
        let requestedDocument = documentID
        let requestID = captureID
        isCapturing = true
        let timeout = DispatchWorkItem { [weak self] in
            guard let self, self.captureID == requestID else { return }
            self.cancelCapture()
            self.errorMessage = "Reading the selection timed out. Select a sentence and try again."
            completion(nil)
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
                completion(nil)
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
                if makeBundledExplanation {
                    self.explanation = ContextValidation.bundledExplanation(for: captured, bundledURL: self.bundledURL)
                    if self.explanation == nil {
                        self.errorMessage = "Selection captured. Ask about it in chat, or open the bundled lesson for its prewritten explanation."
                    }
                }
                if truncated {
                    self.errorMessage = (self.errorMessage.map { $0 + " " } ?? "")
                        + "Page capture was limited to the first 12,000 characters."
                }
                completion(captured)
            } catch let failure as ContextValidation.Failure {
                self.errorMessage = failure.localizedDescription
                completion(nil)
            } catch {
                self.errorMessage = "Couldn't read this page's selection. Try selecting text again, or open the bundled lesson."
                completion(nil)
            }
        }
    }

    func sendMessage(_ prompt: String) {
        guard !isResponding else { return }
        if screenConversation { clearConversation() }
        let prompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty, prompt.utf16.count <= 4_000 else {
            chatError = "Write a question of 1–4,000 characters."
            return
        }
        guard documentReady, !webView.isLoading else {
            chatError = "Wait for the page to load, select a passage, and send again."
            return
        }
        responseID = UUID()
        let requestID = responseID
        let requestedDocument = documentID
        chatError = nil
        isResponding = true
        if !messages.isEmpty, let context, context.documentID == documentID, context.url == webView.url {
            requestReply(prompt: prompt, context: context, requestID: requestID)
        } else {
            // A new conversation always reads the user's current selection explicitly.
            messages = []
            captureSelection(makeBundledExplanation: false) { [weak self] captured in
                guard let self, self.responseID == requestID, self.documentID == requestedDocument else { return }
                guard let captured else {
                    self.isResponding = false
                    self.chatError = self.errorMessage ?? "Select a passage, then send again."
                    return
                }
                self.requestReply(prompt: prompt, context: captured, requestID: requestID)
            }
        }
    }

    /// Sends OCR already captured through the user's active screen-sharing session.
    func sendScreenMessage(_ prompt: String, context: PageContext) {
        guard !isResponding else { return }
        let prompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty, prompt.utf16.count <= 4_000 else {
            chatError = "Write a question of 1–4,000 characters."
            return
        }
        guard context.url.scheme == "duosync", context.url.host == "screen" else {
            chatError = "Start screen sharing and wait for readable text before asking."
            return
        }
        if !screenConversation { clearConversation() }
        screenConversation = true
        cancelCapture()
        self.context = context
        explanation = nil
        errorMessage = nil
        chatError = nil
        responseID = UUID()
        isResponding = true
        requestReply(prompt: prompt, context: context, requestID: responseID)
    }

    private func requestReply(prompt: String, context: PageContext, requestID: UUID) {
        do {
            let endpoint = UserDefaults.standard.string(forKey: "assistantEndpoint") ?? "http://localhost:8766/api/chat"
            guard let url = URL(string: endpoint), ["http", "https"].contains(url.scheme?.lowercased() ?? ""),
                  url.host != nil else { throw ChatTransport.Failure.invalidEndpoint }
            // Retrying a failed/stopped turn must not add another identical user message.
            if messages.last?.role != "user" || messages.last?.content != prompt {
                messages.append(ChatMessage(role: "user", content: prompt))
            }
            let body = try ChatTransport.requestBody(messages: messages, context: context)
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = body
            request.timeoutInterval = 45
            let requestedDocument = documentID
            let isScreenRequest = context.url.scheme == "duosync"
            let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
                DispatchQueue.main.async {
                    guard let self, self.responseID == requestID,
                          isScreenRequest || self.documentID == requestedDocument else { return }
                    self.responseTask = nil
                    self.responseTimeout?.cancel()
                    self.responseTimeout = nil
                    self.isResponding = false
                    guard context.url.scheme == "duosync" || self.webView.url == context.url else {
                        self.clearConversation()
                        self.chatError = "The page changed. Select a passage and start again."
                        return
                    }
                    if let error {
                        self.chatError = (error as NSError).code == NSURLErrorTimedOut
                            ? "The assistant timed out. Check the local server, then retry."
                            : "Couldn't reach the assistant. Start the local server on port 8766 and configure its provider key, then retry."
                        return
                    }
                    do {
                        let text = try ChatTransport.reply(data: data ?? Data(), statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0)
                        self.messages.append(ChatMessage(role: "assistant", content: text))
                    } catch {
                        self.chatError = error.localizedDescription
                    }
                }
            }
            responseTask = task
            let timeout = DispatchWorkItem { [weak self] in
                guard let self, self.responseID == requestID else { return }
                self.cancelResponse()
                self.chatError = "The assistant timed out. Check the local server, then retry."
            }
            responseTimeout = timeout
            DispatchQueue.main.asyncAfter(deadline: .now() + 45, execute: timeout)
            task.resume()
        } catch {
            isResponding = false
            chatError = error.localizedDescription
        }
    }

    func cancelResponse() {
        let wasResponding = isResponding
        responseID = UUID()
        responseTask?.cancel()
        responseTask = nil
        responseTimeout?.cancel()
        responseTimeout = nil
        if wasResponding { cancelCapture() }
        isResponding = false
        if wasResponding { chatError = "Response stopped. Send the same question to retry." }
    }

    func clearConversation() {
        screenConversation = false
        cancelResponse()
        cancelCapture()
        messages = []
        chatError = nil
        context = nil
        explanation = nil
    }

    func clearExplanation() {
        guard !isResponding else { return }
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
        if !screenConversation { clearConversation() }
        cancelCapture()
        documentID = UUID()
        documentReady = false
        isPageLoading = true
        if !screenConversation { context = nil }
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
        isPageLoading = false
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
        isPageLoading = false
        errorMessage = "The page stopped responding. Open the bundled demo or reload its web address."
    }

    private func show(_ error: Error) {
        guard (error as NSError).code != NSURLErrorCancelled else {
            // Superseded navigation may still be loading. A genuinely stopped load must settle.
            if !webView.isLoading && !documentReady {
                cancelCapture()
                isPageLoading = false
                errorMessage = "Page loading was cancelled. Open the bundled demo or reload its web address."
            }
            return
        }
        invalidateDocument()
        isPageLoading = false
        errorMessage = "Couldn't load this page. Try again or open the bundled demo."
    }
}

struct BrowserView: UIViewRepresentable {
    let store: BrowserStore
    func makeUIView(context: Context) -> WKWebView { store.webView }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
