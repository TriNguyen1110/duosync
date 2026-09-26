import Foundation
@main
struct DemoAppStoreTests {
 @MainActor static func main() throws {
  let store = DemoAppStore()
  var count = 0
  func check(_ condition: Bool, _ name: String) { precondition(condition, name); count += 1 }
  check(store.context != nil && store.context!.url.absoluteString.hasSuffix("demo-safari"), "Initial visible app has context")
  let original = store.context!
  store.recordVisible("Not visible", in: .reels)
  check(store.context!.documentID == original.documentID, "Offscreen updates ignored")
  store.recordVisible("Visible article section", in: .safari)
  check(store.context!.selection == "Visible article section" && store.context!.text.contains("Visible article section"), "Scroll observation grounds quote")
  let articleID = store.context!.documentID
  store.recordVisible("Visible article section", in: .safari)
  check(store.context!.documentID == articleID, "Repeated same observation preserves identity")
  store.select(.social)
  store.recordVisible("Visible feed card", in: .social)
  store.select(.reels)
  store.recordVisible("Visible reel caption", in: .reels)
  check(store.recentContexts.count == 3 && store.context!.selection == "Visible reel caption", "Current app and distinct history tracked")
  check(store.recentContexts.map { $0.url.absoluteString } == ["duosync://screen/demo-reels", "duosync://screen/demo-social", "duosync://screen/demo-safari"], "Recent app order follows switches")
  store.select(.safari)
  check(store.context!.selection == "Visible article section" && store.recentContexts.count == 3, "Returning app restores prior excerpt without duplicate")
  for _ in 0..<10 { store.select(.social); store.select(.safari) }
  check(store.recentContexts.count == 3, "Repeated app switches keep bounded distinct history")
  store.recordVisible(String(repeating: "😀", count: 2500), in: .safari)
  check(store.context!.selection.utf16.count == 2000 && store.context!.text.utf16.count <= 12000, "UTF16 observation and combined payload bounds")
  _ = try ChatTransport.requestBody(messages: [ChatMessage(role: "user", content: "Check this")], context: store.context!)
  count += 1
  let beforeEmpty = store.context!.documentID
  store.recordVisible("", in: .safari)
  check(store.context!.documentID == beforeEmpty, "Empty observation does not overwrite source")
  print("PASS: \(count) DemoAppStore state regressions")
  print("UNVERIFIED: SwiftUI scroll-position callbacks, layout and conversation UI require native execution")
 }
}
