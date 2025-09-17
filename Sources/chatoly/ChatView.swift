import SwiftUI

struct ChatView: View {
    @StateObject private var chatClient: YouTubeChatClient

    init(videoId: String) {
        self._chatClient = StateObject(wrappedValue: YouTubeChatClient(videoId: videoId))
    }

    var body: some View {
        ZStack {
            // Frosted glass background
            VisualEffectView(effect: NSVisualEffectView.Material.hudWindow, blendingMode: .behindWindow)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Drag handle at the top
                DragHandle()
                    .frame(height: 15)

                // Chat messages
                ScrollViewReader { proxy in
                    ScrollView(.vertical) {
                        LazyVStack(alignment: .leading, spacing: 8) {
                            ForEach(chatClient.messages) { message in
                                ChatMessageView(message: message)
                                    .id(message.id)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                    }
                    .onChange(of: chatClient.messages.count) { _ in
                        // Auto-scroll to bottom with new messages
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            if let lastMessage = chatClient.messages.last {
                                withAnimation(.easeOut(duration: 0.3)) {
                                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                        }
                    }
                }

                // Status bar at the bottom
                HStack {
                    Circle()
                        .fill(chatClient.isConnected ? .green : .red)
                        .frame(width: 8, height: 8)

                    Text(statusText)
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text("\(chatClient.messages.count) messages")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial)
            }
        }
        .frame(minWidth: 300, minHeight: 200)
        .task {
            do {
                try await chatClient.initialize()
                await chatClient.startStreaming()
            } catch {
                print("Failed to initialize chat: \(error)")
            }
        }
        .onDisappear {
            chatClient.stopStreaming()
        }
    }

    private var statusText: String {
        if let error = chatClient.error {
            return "Error: \(error)"
        } else if chatClient.isConnected {
            return "Connected"
        } else {
            return "Connecting..."
        }
    }
}

struct ChatMessageView: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // Avatar
            AsyncImage(url: URL(string: message.authorPhoto ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(.gray.opacity(0.3))
                    .overlay {
                        Text(message.author.prefix(1).uppercased())
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
            }
            .frame(width: 24, height: 24)
            .clipShape(Circle())

            // Message content
            VStack(alignment: .leading, spacing: 2) {
                // Author name with badges and purchase amount
                HStack(spacing: 4) {
                    Text(message.author)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(authorColor)

                    // Badges
                    ForEach(message.badges, id: \.self) { badge in
                        Text(badge)
                            .font(.caption2)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(.blue.opacity(0.2))
                            .foregroundColor(.blue)
                            .clipShape(Capsule())
                    }

                    // Purchase amount for paid messages
                    if let amount = message.purchaseAmount {
                        Text(amount)
                            .font(.caption2)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(.yellow.opacity(0.3))
                            .foregroundColor(.orange)
                            .clipShape(Capsule())
                    }

                    Spacer()
                }

                // Message text
                Text(message.message)
                    .font(.system(.caption, design: .default))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(.vertical, 2)
        .background(messageBackground)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private var authorColor: Color {
        switch message.type {
        case .membership:
            return .green
        case .paid:
            return .yellow
        case .ticker:
            return .purple
        case .text:
            return .primary
        }
    }

    private var messageBackground: Color {
        switch message.type {
        case .membership:
            return .green.opacity(0.1)
        case .paid:
            return .yellow.opacity(0.1)
        case .ticker:
            return .purple.opacity(0.1)
        case .text:
            return .clear
        }
    }
}

// Helper view for visual effects
struct VisualEffectView: NSViewRepresentable {
    let effect: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = effect
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = effect
        nsView.blendingMode = blendingMode
    }
}

#Preview {
    ChatView(videoId: "dQw4w9WgXcQ")
        .frame(width: 350, height: 500)
}