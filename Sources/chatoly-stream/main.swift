import Foundation

// Main entry point
print("🚀 Starting Chatoly Stream...", terminator: "\n")
fflush(stdout)

Task {
    print("📝 Task started")
    fflush(stdout)
    await runChatolyStream()
    print("✅ Task completed, exiting...")
    fflush(stdout)
    exit(0)
}

print("🔄 Running event loop...", terminator: "\n")
fflush(stdout)
RunLoop.main.run()

func runChatolyStream() async {
        print("👋 runChatolyStream started")
        fflush(stdout)

        // Get video ID from command line arguments or use default
        let arguments = CommandLine.arguments
        let videoId: String

        if arguments.count > 1 {
            videoId = arguments[1]
        } else {
            print("Usage: chatoly-stream <video-id>")
            print("Example: chatoly-stream Rmv0Gxromy4")
            print("\nUsing default video ID...")
            videoId = "n5f3nhoofYk"
        }

        print("🎥 Chatoly Stream - YouTube Live Chat Monitor")
        print("📺 Video ID: \(videoId)")
        print("🔄 Initializing...")
        fflush(stdout)

        var retryCount = 0
        let maxRetries = 60  // Try for up to 5 minutes (60 * 5 seconds)

        while retryCount < maxRetries {
            let client = YouTubeChatClient(videoId: videoId)

            do {
                // Initialize the client by fetching the YouTube page and extracting credentials
                try await client.initialize()

                print("✅ Successfully initialized!")
                print("💬 Starting chat stream...")
                print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

                // Start streaming chat messages
                try await client.startStreaming { message in
                    printChatMessage(message)
                }

                // If we get here, streaming ended normally
                break

            } catch {
                retryCount += 1

                if retryCount >= maxRetries {
                    print("❌ Failed after \(maxRetries) attempts. Giving up.")
                    print("Final error: \(error.localizedDescription)")
                    exit(1)
                }

                print("⚠️  Attempt \(retryCount)/\(maxRetries) failed: \(error.localizedDescription)")

                if case YouTubeChatError.credentialsNotFound = error {
                    print("   Waiting for stream to become available...")
                } else if case YouTubeChatError.apiRequestFailed = error {
                    print("   API request failed, retrying...")
                } else if case YouTubeChatError.continuationNotFound = error {
                    print("   Continuation token not found, retrying...")
                } else {
                    print("   Unexpected error, retrying...")
                }

                print("   Retrying in 5 seconds...")

                // Wait 5 seconds before retrying
                try? await Task.sleep(nanoseconds: 5_000_000_000)
            }
        }
}

func printChatMessage(_ message: ChatMessage) {
    let timestamp = DateFormatter.timeFormatter.string(from: message.timestamp)
    let typeIndicator = getTypeIndicator(for: message.type)
    let badgeText = message.badges.isEmpty ? "" : " [\(message.badges.joined(separator: ", "))]"
    let purchaseText = message.purchaseAmount != nil ? " (\(message.purchaseAmount!))" : ""

    print("\(typeIndicator) [\(timestamp)] \(message.author)\(badgeText)\(purchaseText): \(message.message)")
}

func getTypeIndicator(for type: MessageType) -> String {
    switch type {
    case .text:
        return "💬"
    case .membership:
        return "🎗️ "
    case .paid:
        return "💰"
    case .ticker:
        return "🎟️ "
    }
}

extension DateFormatter {
    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()
}