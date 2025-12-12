/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation
import UIKit

/// Central service for managing LLM interactions and conversation state.
@MainActor
class LLMService: ObservableObject {
  @Published var messages: [LLMMessage] = []
  @Published var isGenerating: Bool = false
  @Published var error: String?
  
  private var activeProvider: LLMProvider
  
  init(provider: LLMProvider) {
    self.activeProvider = provider
  }
  
  /// Sends a message to the active LLM provider and streams the response.
  /// - Parameters:
  ///   - content: The user's text message.
  ///   - image: Optional image to include in the context (multimodal).
  func sendMessage(_ content: String, image: UIImage? = nil) async {
    isGenerating = true
    error = nil
    
    // 1. Add user message to history
    let userMsg = LLMMessage(role: .user, content: content, image: image)
    messages.append(userMsg)
    
    // 2. Create a placeholder for the assistant's response
    var assistantMsg = LLMMessage(role: .assistant, content: "")
    messages.append(assistantMsg)
    let assistantMsgIndex = messages.count - 1
    
    do {
      // 3. Stream the response
      let stream = try await activeProvider.streamChat(messages: messages.dropLast()) // Exclude the empty placeholder
      
      for try await chunk in stream {
        // Update the last message in real-time
        assistantMsg.content += chunk
        // Force UI update by re-assigning the modified message
        messages[assistantMsgIndex] = assistantMsg
      }
      
    } catch {
      self.error = error.localizedDescription
      // Remove the empty/partial placeholder if it failed completely?
      // For now, we leave it so the user can see partial results or retry.
      print("LLM Generation Error: \(error)")
    }
    
    isGenerating = false
  }
  
  /// Clears the conversation history.
  func clearHistory() {
    messages = []
    error = nil
    isGenerating = false
  }
  
  /// Updates the active provider (e.g. switching from OpenAI to Anthropic).
  func setProvider(_ provider: LLMProvider) {
    self.activeProvider = provider
  }
}

