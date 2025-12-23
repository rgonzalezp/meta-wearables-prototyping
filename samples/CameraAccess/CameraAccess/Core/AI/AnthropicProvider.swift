/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation
import UIKit

/// A concrete implementation of LLMProvider for Anthropic's API.
class AnthropicProvider: LLMProvider {
  let id = "anthropic"
  let name = "Anthropic Claude 3.5 Sonnet"
  
  private let apiKey: String
  private let model: String
  
  init(apiKey: String, model: String = "claude-3-5-sonnet-20240620") {
    self.apiKey = apiKey
    self.model = model
  }
  
  func streamChat(messages: [LLMMessage]) async throws -> AsyncThrowingStream<String, Error> {
    return AsyncThrowingStream { continuation in
      Task {
        do {
          let url = URL(string: "https://api.anthropic.com/v1/messages")!
          var request = URLRequest(url: url)
          request.httpMethod = "POST"
          request.addValue(apiKey, forHTTPHeaderField: "x-api-key")
          request.addValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
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
            print("Anthropic Error: \(errorText)")
            
            if httpResponse.statusCode == 401 {
              throw LLMError.invalidAPIKey
            } else if httpResponse.statusCode == 429 {
              throw LLMError.rateLimitExceeded
            } else {
              throw LLMError.providerError("Status code: \(httpResponse.statusCode)")
            }
          }
          
          for try await line in result.lines {
            guard line.hasPrefix("data: ") else { continue }
            
            let data = line.dropFirst(6).data(using: .utf8)!
            
            // Handle "data: [DONE]" if Anthropic sends it (though typically they send event types)
            // Anthropic SSE format involves event types.
            // But URLSession.bytes gives lines.
            // Typical event stream:
            // event: content_block_delta
            // data: {"type": "content_block_delta", "index": 0, "delta": {"type": "text_delta", "text": "Hello"}}
            
            // We are processing lines. We might see "event: ..." lines which we can ignore,
            // and "data: ..." lines which contain the payload.
            
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                // Check for message_stop or similar to end?
                if let type = json["type"] as? String {
                    if type == "content_block_delta" {
                        if let delta = json["delta"] as? [String: Any],
                           let text = delta["text"] as? String {
                            continuation.yield(text)
                        }
                    } else if type == "message_stop" {
                        // End of message
                    } else if type == "error" {
                        // Handle in-stream error if possible
                         if let error = json["error"] as? [String: Any],
                            let message = error["message"] as? String {
                             throw LLMError.providerError(message)
                         }
                    }
                }
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
    // Anthropic separates system prompt from messages list
    let systemMessages = messages.filter { $0.role == .system }
    let systemPrompt = systemMessages.map { $0.content }.joined(separator: "\n")
    
    // Filter out system messages for the main messages list
    let conversationMessages = messages.filter { $0.role != .system }
    
    let apiMessages: [[String: Any]] = conversationMessages.map { msg in
      var content: [Any] = []
      
        // Add image if present (before text, or after? Anthropic supports mixed. Usually image then text is good for context)
      if let image = msg.image, let imageData = image.jpegData(compressionQuality: 0.5) {
        let base64Image = imageData.base64EncodedString()
        content.append([
          "type": "image",
          "source": [
            "type": "base64",
            "media_type": "image/jpeg",
            "data": base64Image
          ]
        ])
      }
        
      content.append([
        "type": "text",
        "text": msg.content
      ])
      
      return [
        "role": msg.role.rawValue, // "user" or "assistant"
        "content": content
      ]
    }
    
    var body: [String: Any] = [
      "model": model,
      "messages": apiMessages,
      "max_tokens": 1024,
      "stream": true
    ]
    
    if !systemPrompt.isEmpty {
        body["system"] = systemPrompt
    }
      
    return body
  }
}

