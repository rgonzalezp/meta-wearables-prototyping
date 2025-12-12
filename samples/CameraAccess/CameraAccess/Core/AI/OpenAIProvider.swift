/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation
import UIKit

/// A concrete implementation of LLMProvider for OpenAI's API.
class OpenAIProvider: LLMProvider {
  let id = "openai"
  let name = "OpenAI GPT-4o"
  
  private let apiKey: String
  private let model: String
  
  init(apiKey: String, model: String = "gpt-4o") {
    self.apiKey = apiKey
    self.model = model
  }
  
  func streamChat(messages: [LLMMessage]) async throws -> AsyncThrowingStream<String, Error> {
    return AsyncThrowingStream { continuation in
      Task {
        do {
          let url = URL(string: "https://api.openai.com/v1/chat/completions")!
          var request = URLRequest(url: url)
          request.httpMethod = "POST"
          request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
          request.addValue("application/json", forHTTPHeaderField: "Content-Type")
          
          let requestBody = try buildRequestBody(messages: messages)
          request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
          
          let (result, response) = try await URLSession.shared.bytes(for: request)
          
          guard let httpResponse = response as? HTTPURLResponse else {
            throw LLMError.invalidResponse
          }
          
          guard httpResponse.statusCode == 200 else {
            // Read error body for debugging
            var errorText = ""
            for try await byte in result {
                if let char = String(bytes: [byte], encoding: .utf8) {
                    errorText += char
                }
            }
            print("OpenAI Error: \(errorText)")
            
            if httpResponse.statusCode == 401 {
              throw LLMError.invalidAPIKey
            } else if httpResponse.statusCode == 429 {
              throw LLMError.rateLimitExceeded
            } else {
              throw LLMError.providerError("Status code: \(httpResponse.statusCode)")
            }
          }
          
          for try await line in result.lines {
            guard line.hasPrefix("data: "), line != "data: [DONE]" else { continue }
            
            let data = line.dropFirst(6).data(using: .utf8)!
            
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let choices = json["choices"] as? [[String: Any]],
               let firstChoice = choices.first,
               let delta = firstChoice["delta"] as? [String: Any],
               let content = delta["content"] as? String {
              
              continuation.yield(content)
            }
          }
          
          continuation.finish()
          
        } catch {
          continuation.finish(throwing: error)
        }
      }
    }
  }
  
  private func buildRequestBody(messages: [LLMMessage]) throws -> [String: Any] {
    let apiMessages: [[String: Any]] = messages.map { msg in
      var content: [Any] = [
        ["type": "text", "text": msg.content]
      ]
      
      // If message has an image, encode it as base64
      if let image = msg.image, let imageData = image.jpegData(compressionQuality: 0.5) {
        let base64Image = imageData.base64EncodedString()
        content.append([
          "type": "image_url",
          "image_url": [
            "url": "data:image/jpeg;base64,\(base64Image)"
          ]
        ])
      }
      
      return [
        "role": msg.role.rawValue,
        "content": content
      ]
    }
    
    return [
      "model": model,
      "messages": apiMessages,
      "stream": true
    ]
  }
}

