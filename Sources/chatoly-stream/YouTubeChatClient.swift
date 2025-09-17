import Foundation

// MARK: - Data Models

struct YouTubeChatResponse: Codable {
    let contents: ResponseContents?
    let continuationContents: ContinuationContents?
}

struct ResponseContents: Codable {
    let liveChatRenderer: LiveChatRenderer?
}

struct ContinuationContents: Codable {
    let liveChatContinuation: LiveChatContinuation?
}

struct LiveChatRenderer: Codable {
    let continuations: [Continuation]?
    let actions: [ChatAction]?
}

struct LiveChatContinuation: Codable {
    let continuations: [Continuation]?
    let actions: [ChatAction]?
}

struct Continuation: Codable {
    let invalidationContinuationData: InvalidationContinuationData?
    let timedContinuationData: TimedContinuationData?
}

struct InvalidationContinuationData: Codable {
    let continuation: String?
    let timeoutMs: Int?
}

struct TimedContinuationData: Codable {
    let continuation: String?
    let timeoutMs: Int?
}

struct ChatAction: Codable {
    let addChatItemAction: AddChatItemAction?
    let addLiveChatTickerItemAction: AddLiveChatTickerItemAction?
}

struct AddChatItemAction: Codable {
    let item: ChatItem?
}

struct AddLiveChatTickerItemAction: Codable {
    let item: TickerItem?
}

struct ChatItem: Codable {
    let liveChatTextMessageRenderer: LiveChatTextMessageRenderer?
    let liveChatMembershipItemRenderer: LiveChatMembershipItemRenderer?
    let liveChatPaidMessageRenderer: LiveChatPaidMessageRenderer?
}

struct TickerItem: Codable {
    let liveChatTickerPaidMessageItemRenderer: LiveChatTickerPaidMessageItemRenderer?
}

struct LiveChatTextMessageRenderer: Codable {
    let message: MessageRuns?
    let authorName: SimpleText?
    let authorPhoto: AuthorPhoto?
    let contextMenuEndpoint: ContextMenuEndpoint?
    let id: String?
    let timestampUsec: String?
    let authorBadges: [AuthorBadge]?
}

struct LiveChatMembershipItemRenderer: Codable {
    let authorName: SimpleText?
    let headerSubtext: MessageRuns?
    let authorPhoto: AuthorPhoto?
    let id: String?
    let timestampUsec: String?
    let authorBadges: [AuthorBadge]?
}

struct LiveChatPaidMessageRenderer: Codable {
    let message: MessageRuns?
    let authorName: SimpleText?
    let purchaseAmountText: SimpleText?
    let authorPhoto: AuthorPhoto?
    let id: String?
    let timestampUsec: String?
    let authorBadges: [AuthorBadge]?
    let bodyBackgroundColor: Int64?
    let headerBackgroundColor: Int64?
}

struct LiveChatTickerPaidMessageItemRenderer: Codable {
    let amount: SimpleText?
    let authorPhoto: AuthorPhoto?
    let durationSec: Int?
}

struct MessageRuns: Codable {
    let runs: [MessageRun]?
}

struct MessageRun: Codable {
    let text: String?
    let emoji: Emoji?
}

struct Emoji: Codable {
    let emojiId: String?
    let shortcuts: [String]?
    let searchTerms: [String]?
    let image: EmojiImage?
}

struct EmojiImage: Codable {
    let thumbnails: [Thumbnail]?
}

struct SimpleText: Codable {
    let simpleText: String?
}

struct AuthorPhoto: Codable {
    let thumbnails: [Thumbnail]?
}

struct Thumbnail: Codable {
    let url: String?
    let width: Int?
    let height: Int?
}

struct ContextMenuEndpoint: Codable {
    let liveChatItemContextMenuEndpoint: LiveChatItemContextMenuEndpoint?
}

struct LiveChatItemContextMenuEndpoint: Codable {
    let params: String?
}

struct AuthorBadge: Codable {
    let liveChatAuthorBadgeRenderer: LiveChatAuthorBadgeRenderer?
}

struct LiveChatAuthorBadgeRenderer: Codable {
    let customThumbnail: AuthorPhoto?
    let icon: Icon?
    let tooltip: String?
}

struct Icon: Codable {
    let iconType: String?
}

// MARK: - Chat Message Model

struct ChatMessage {
    let id: String
    let author: String
    let message: String
    let timestamp: Date
    let authorPhoto: String?
    let badges: [String]
    let type: MessageType
    let purchaseAmount: String?
}

enum MessageType {
    case text
    case membership
    case paid
    case ticker
}

// MARK: - YouTube Chat Client

class YouTubeChatClient {
    private let videoId: String
    private var apiKey: String?
    private var clientVersion: String?
    private var continuation: String?
    private var session: URLSession

    // Regex patterns for extracting data from YouTube page
    private let apiKeyPattern = #""INNERTUBE_API_KEY":"([^"]+)""#
    private let clientVersionPattern = #""clientVersion":"([^"]+)""#
    private let continuationPattern = #""continuation":"([^"]+)""#

    init(videoId: String) {
        self.videoId = videoId
        self.session = URLSession.shared
    }

    // MARK: - Public Methods

    func initialize() async throws {
        print("Initializing YouTube chat client for video: \(videoId)")

        let url = URL(string: "https://www.youtube.com/watch?v=\(videoId)")!
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36", forHTTPHeaderField: "User-Agent")

        let (data, _) = try await session.data(for: request)
        let html = String(data: data, encoding: .utf8) ?? ""

        // Debug: Check if we got HTML
        print("HTML length: \(html.count)")

        try extractCredentials(from: html)

        print("API Key found: \(apiKey ?? "none")")
        print("Client Version found: \(clientVersion ?? "none")")

        try extractContinuation(from: html)

        print("Continuation found: \(continuation?.prefix(50) ?? "none")...")

        print("Initialization complete:")
        print("- API Key: \(apiKey?.prefix(20) ?? "nil")...")
        print("- Client Version: \(clientVersion ?? "nil")")
        print("- Continuation: \(continuation?.prefix(20) ?? "nil")...")
    }

    func startStreaming(onMessage: @escaping (ChatMessage) -> Void) async throws {
        guard let apiKey = apiKey,
              let clientVersion = clientVersion,
              var continuation = continuation else {
            throw YouTubeChatError.notInitialized
        }

        print("Starting chat stream...")

        while true {
            do {
                let response = try await fetchChatData(
                    apiKey: apiKey,
                    clientVersion: clientVersion,
                    continuation: continuation
                )

                let messages = parseChatMessages(from: response)
                for message in messages {
                    onMessage(message)
                }

                // Update continuation for next request
                if let newContinuation = extractContinuation(from: response) {
                    continuation = newContinuation
                }

                // Wait before next poll (YouTube typically uses 1-3 second intervals)
                try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds

            } catch {
                print("Error fetching chat data: \(error)")
                // Wait longer before retrying on error
                try await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
            }
        }
    }

    // MARK: - Private Methods

    private func extractCredentials(from html: String) throws {
        // Extract API key
        let apiKeyRegex = try NSRegularExpression(pattern: apiKeyPattern)
        let apiKeyRange = NSRange(location: 0, length: html.utf16.count)

        if let apiKeyMatch = apiKeyRegex.firstMatch(in: html, range: apiKeyRange) {
            let matchRange = apiKeyMatch.range(at: 1)
            if let range = Range(matchRange, in: html) {
                self.apiKey = String(html[range])
            }
        }

        // Extract client version
        let clientVersionRegex = try NSRegularExpression(pattern: clientVersionPattern)
        let clientVersionRange = NSRange(location: 0, length: html.utf16.count)

        if let clientVersionMatch = clientVersionRegex.firstMatch(in: html, range: clientVersionRange) {
            let matchRange = clientVersionMatch.range(at: 1)
            if let range = Range(matchRange, in: html) {
                self.clientVersion = String(html[range])
            }
        }

        if apiKey == nil || clientVersion == nil {
            throw YouTubeChatError.credentialsNotFound
        }
    }

    private func extractContinuation(from html: String) throws {
        let continuationRegex = try NSRegularExpression(pattern: continuationPattern)
        let range = NSRange(location: 0, length: html.utf16.count)

        // Debug: Find all matches to see what we're getting
        let matches = continuationRegex.matches(in: html, range: range)
        print("Found \(matches.count) continuation matches")

        if let match = continuationRegex.firstMatch(in: html, range: range) {
            let matchRange = match.range(at: 1)
            if let range = Range(matchRange, in: html) {
                self.continuation = String(html[range])
                print("First continuation: \(self.continuation?.prefix(100) ?? "")")
            }
        }

        if continuation == nil {
            throw YouTubeChatError.continuationNotFound
        }
    }

    private func extractContinuation(from response: YouTubeChatResponse) -> String? {
        // Try continuation contents first
        if let continuations = response.continuationContents?.liveChatContinuation?.continuations {
            for continuation in continuations {
                if let invalidationData = continuation.invalidationContinuationData {
                    return invalidationData.continuation
                }
                if let timedData = continuation.timedContinuationData {
                    return timedData.continuation
                }
            }
        }

        // Try regular contents
        if let continuations = response.contents?.liveChatRenderer?.continuations {
            for continuation in continuations {
                if let invalidationData = continuation.invalidationContinuationData {
                    return invalidationData.continuation
                }
                if let timedData = continuation.timedContinuationData {
                    return timedData.continuation
                }
            }
        }

        return nil
    }

    private func fetchChatData(apiKey: String, clientVersion: String, continuation: String) async throws -> YouTubeChatResponse {
        let url = URL(string: "https://www.youtube.com/youtubei/v1/live_chat/get_live_chat?key=\(apiKey)")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("https://www.youtube.com", forHTTPHeaderField: "Origin")
        request.setValue("https://www.youtube.com/watch?v=\(videoId)", forHTTPHeaderField: "Referer")

        let requestBody: [String: Any] = [
            "context": [
                "client": [
                    "clientName": "WEB",
                    "clientVersion": clientVersion,
                    "hl": "en",
                    "gl": "US",
                    "utcOffsetMinutes": 0
                ]
            ],
            "continuation": continuation
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw YouTubeChatError.apiRequestFailed
        }

        let chatResponse = try JSONDecoder().decode(YouTubeChatResponse.self, from: data)
        return chatResponse
    }

    private func parseChatMessages(from response: YouTubeChatResponse) -> [ChatMessage] {
        var messages: [ChatMessage] = []

        let actions = response.continuationContents?.liveChatContinuation?.actions ??
                     response.contents?.liveChatRenderer?.actions ?? []

        for action in actions {
            if let addChatItemAction = action.addChatItemAction {
                if let message = parseChatItem(addChatItemAction.item) {
                    messages.append(message)
                }
            }

            if let addTickerAction = action.addLiveChatTickerItemAction {
                if let message = parseTickerItem(addTickerAction.item) {
                    messages.append(message)
                }
            }
        }

        return messages
    }

    private func parseChatItem(_ item: ChatItem?) -> ChatMessage? {
        guard let item = item else { return nil }

        if let textRenderer = item.liveChatTextMessageRenderer {
            return ChatMessage(
                id: textRenderer.id ?? UUID().uuidString,
                author: textRenderer.authorName?.simpleText ?? "Unknown",
                message: extractMessageText(from: textRenderer.message),
                timestamp: parseTimestamp(textRenderer.timestampUsec),
                authorPhoto: textRenderer.authorPhoto?.thumbnails?.first?.url,
                badges: extractBadges(from: textRenderer.authorBadges),
                type: .text,
                purchaseAmount: nil
            )
        }

        if let membershipRenderer = item.liveChatMembershipItemRenderer {
            return ChatMessage(
                id: membershipRenderer.id ?? UUID().uuidString,
                author: membershipRenderer.authorName?.simpleText ?? "Unknown",
                message: extractMessageText(from: membershipRenderer.headerSubtext) + " (New Member)",
                timestamp: parseTimestamp(membershipRenderer.timestampUsec),
                authorPhoto: membershipRenderer.authorPhoto?.thumbnails?.first?.url,
                badges: extractBadges(from: membershipRenderer.authorBadges),
                type: .membership,
                purchaseAmount: nil
            )
        }

        if let paidRenderer = item.liveChatPaidMessageRenderer {
            return ChatMessage(
                id: paidRenderer.id ?? UUID().uuidString,
                author: paidRenderer.authorName?.simpleText ?? "Unknown",
                message: extractMessageText(from: paidRenderer.message),
                timestamp: parseTimestamp(paidRenderer.timestampUsec),
                authorPhoto: paidRenderer.authorPhoto?.thumbnails?.first?.url,
                badges: extractBadges(from: paidRenderer.authorBadges),
                type: .paid,
                purchaseAmount: paidRenderer.purchaseAmountText?.simpleText
            )
        }

        return nil
    }

    private func parseTickerItem(_ item: TickerItem?) -> ChatMessage? {
        guard let item = item,
              let tickerRenderer = item.liveChatTickerPaidMessageItemRenderer else { return nil }

        return ChatMessage(
            id: UUID().uuidString,
            author: "Ticker",
            message: "Super Chat Ticker",
            timestamp: Date(),
            authorPhoto: tickerRenderer.authorPhoto?.thumbnails?.first?.url,
            badges: [],
            type: .ticker,
            purchaseAmount: tickerRenderer.amount?.simpleText
        )
    }

    private func extractMessageText(from messageRuns: MessageRuns?) -> String {
        guard let runs = messageRuns?.runs else { return "" }

        return runs.compactMap { run in
            if let text = run.text {
                return text
            } else if let emoji = run.emoji {
                return emoji.shortcuts?.first ?? "😀"
            }
            return nil
        }.joined()
    }

    private func extractBadges(from badges: [AuthorBadge]?) -> [String] {
        guard let badges = badges else { return [] }

        return badges.compactMap { badge in
            badge.liveChatAuthorBadgeRenderer?.tooltip
        }
    }

    private func parseTimestamp(_ timestampUsec: String?) -> Date {
        guard let timestampUsec = timestampUsec,
              let microseconds = Int64(timestampUsec) else {
            return Date()
        }

        let seconds = Double(microseconds) / 1_000_000.0
        return Date(timeIntervalSince1970: seconds)
    }
}

// MARK: - Errors

enum YouTubeChatError: Error, LocalizedError {
    case notInitialized
    case credentialsNotFound
    case continuationNotFound
    case apiRequestFailed

    var errorDescription: String? {
        switch self {
        case .notInitialized:
            return "YouTube chat client not initialized. Call initialize() first."
        case .credentialsNotFound:
            return "Could not extract API credentials from YouTube page."
        case .continuationNotFound:
            return "Could not extract continuation token from YouTube page."
        case .apiRequestFailed:
            return "YouTube API request failed."
        }
    }
}