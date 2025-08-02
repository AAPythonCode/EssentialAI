//
//  ContentView.swift
//  aiTest
//
//  Created by Aarnav Dhir on 7/31/25.
//

import SwiftUI

struct ContentView: View {
    @State private var userResponse: String = ""
    @State private var responseFromAi: String = "Send your question."
    @State private var aiModel: String = ""
    @State private var disabled: Bool = true
    
    var body: some View {
        
        let aiModelIDs: [String] = [
            "allam-2-7b",
            "compound-beta",
            "compound-beta-mini",
            "deepseek-r1-distill-llama-70b",
            "distil-whisper-large-v3-en",
            "gemma2-9b-it",
            "llama-3.1-8b-instant",
            "llama-3.3-70b-versatile",
            "llama3-70b-8192",
            "llama3-8b-8192",
            "meta-llama/llama-4-maverick-17b-128e-instruct",
            "meta-llama/llama-4-scout-17b-16e-instruct",
            "meta-llama/llama-guard-4-12b",
            "moonshotai/kimi-k2-instruct",
            "playai-tts",
            "playai-tts-arabic",
            "qwen/qwen3-32b",
            "whisper-large-v3",
            "whisper-large-v3-turbo"
        ]
        
        ZStack {
            Color(.tan)
                .ignoresSafeArea()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            VStack {
                Text("")
                .padding()
                Text("Welcome to")
                    .font(.custom("GmarketSansLight", size: 30))
                Text("Essential AI!")
                    .font(.custom("GmarketSansBold", size: 40))
                Text("Choose your AI Model below.")
                    .padding()
                    .font(.custom("GmarketSansLight", size: 20))
                Text("↓")
                Picker("Select", selection: $aiModel) {
                    ForEach(aiModelIDs, id: \.self) {
                        Text($0).font(.custom("GmarketSansLight", size: 20))
                    }
                }
                .pickerStyle(.menu).padding()
                .font(.custom("GmarketSansLight", size: 20))
                ZStack {
                    RoundedRectangle(cornerSize: CGSize(width: 10, height: 10))
                        .frame(height: 50)
                        .foregroundStyle(.green)
                    
                    TextField("Speak your mind!", text: $userResponse)
                        .multilineTextAlignment(.center)
                        .font(.custom("GmarketSansLight", size: 20))
                }
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .frame(height: 50)
                        .foregroundStyle(.blue)
                    
                    Button() {
                        Task {
                            do {
                                let response = try await extractApiResponse(userQ: userResponse, aiModel: aiModel)
                                responseFromAi = response
                                userResponse = ""
                            } catch {
                                responseFromAi = "❌ Error: \(error.localizedDescription)"
                            }
                        }
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .frame(height: 50)
                                .foregroundStyle(disabled ? .gray : .blue)
                            if aiModel != "" {
                                Text("Send question to \(aiModel)!")
                                    .foregroundStyle(.black)
                                    .font(.custom("GmarketSansLight", size: 20))
                            } else {
                                Text("Choose a model.")
                                    .foregroundStyle(.black)
                                    .font(.custom("GmarketSansLight", size: 20))
                            }
                        }
                    }
                    .disabled(disabled)
                }
                ScrollView {
                    Text(stripThinkTags(from: responseFromAi))
                        .multilineTextAlignment(.center)
                        .padding()
                }
            }
            
            .onChange(of: aiModel) { newValue in
                disabled = newValue.isEmpty
            }
            .padding()
        }
    }
}

func extractApiResponse(userQ: String, aiModel: String) async throws -> String {
    let url = URL(string:  "https://api.groq.com/openai/v1/chat/completions")!
    
    var request = URLRequest(url: url)
    
    request.httpMethod = "POST"
    request.addValue("Bearer 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", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    let clarity = ""
    let apiRequest = ChatRequest(model: aiModel, messages: [Message(role: "user", content: "\(userQ) \(clarity)")])
    
    let theRequester = try JSONEncoder().encode(apiRequest)
    request.httpBody = theRequester
    
    let (data, _) = try await URLSession.shared.data(for: request)
    
    let decoded = try JSONDecoder().decode(ChatResponse.self, from: data)
    print("📦 Raw JSON:", String(data: data, encoding: .utf8) ?? "Invalid JSON")
    return decoded.choices.first?.message.content ?? "☹️"
}

struct ChatRequest: Encodable {
    let model: String
    let messages: [Message]
}

struct Message: Codable {
    let role: String
    let content: String
}

struct ChatResponse: Codable {
    let choices: [Choice]

    struct Choice: Codable {
        let message: Message
    }
}

func stripThinkTags(from text: String) -> String {
    let pattern = "<think>.*?</think>"
    let regex = try! NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators])
    let range = NSRange(location: 0, length: text.utf16.count)
    return regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: "")
}

#Preview {
    ContentView()
}
