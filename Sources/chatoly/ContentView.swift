import SwiftUI

struct ContentView: View {
    @State private var youtubeURL: String = ""
    @State private var showWebView: Bool = false
    @State private var chatURL: String = ""
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        Group {
            if showWebView {
                ZStack(alignment: .top) {
                    WebView(url: chatURL)
                        .frame(minWidth: 200, minHeight: 150)

                    // Draggable area at the top
                    DragHandle()
                        .frame(height: 15)
                        .frame(maxWidth: .infinity)
                }
            } else {
                VStack(spacing: 20) {
                    Text("YouTube Chat Overlay")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("Enter YouTube video or live stream URL:")
                        .font(.headline)

                    TextField("https://www.youtube.com/watch?v=...", text: $youtubeURL)
                        .textFieldStyle(.roundedBorder)
                        .frame(minWidth: 200, maxWidth: 500)
                        .focused($isTextFieldFocused)

                    Button("Load Chat") {
                        loadChat()
                    }
                    .disabled(youtubeURL.isEmpty)
                    .keyboardShortcut(.defaultAction)
                }
                .padding()
                .frame(minWidth: 250, minHeight: 150)
            }
        }
        .onAppear {
            // Set focus to text field after window setup
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isTextFieldFocused = true
            }
        }
    }

    private func loadChat() {
        guard let videoID = extractVideoID(from: youtubeURL) else {
            return
        }

        chatURL = "https://www.youtube.com/live_chat?v=\(videoID)"
        showWebView = true
    }

    private func extractVideoID(from url: String) -> String? {
        let patterns = [
            "v=([a-zA-Z0-9_-]{11})",
            "youtu.be/([a-zA-Z0-9_-]{11})",
            "embed/([a-zA-Z0-9_-]{11})"
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: url, range: NSRange(url.startIndex..., in: url)) {
                if let range = Range(match.range(at: 1), in: url) {
                    return String(url[range])
                }
            }
        }

        return nil
    }
}