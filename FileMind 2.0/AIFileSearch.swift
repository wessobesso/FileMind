//
//  AIFileSearch.swift
//  FileMind
//
//  Created by WessoBesso on 2025-05-10.
//

import Foundation

struct ChatRequest: Codable {
    let model: String
    let messages: [Message]
}

struct Message: Codable {
    let role: String
    let content: String
}

struct ChatResponse: Codable {
    struct Choice: Codable {
        let message: Message
    }
    let choices: [Choice]
}

class AIFileSearcher {
    static let shared = AIFileSearcher()

    //API KEY
    private let apiKey = "na na na boo boo no api key for you"

    func searchFiles(with userInput: String, completion: @escaping (String?) -> Void) {
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let systemPrompt = "You are helping find files. Given a user’s input, return a list of 3 descriptive keywords or tags to help match filenames."

        let messages = [
            Message(role: "system", content: systemPrompt),
            Message(role: "user", content: userInput)
        ]

        let body = ChatRequest(model: "gpt-4", messages: messages)

        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            completion(nil)
            return
        }

        URLSession.shared.dataTask(with: request) { data, _, error in
            guard let data = data, error == nil else {
                completion(nil)
                return
            }

            do {
                let result = try JSONDecoder().decode(ChatResponse.self, from: data)
                completion(result.choices.first?.message.content)
            } catch {
                completion(nil)
            }
        }.resume()
    }
}
