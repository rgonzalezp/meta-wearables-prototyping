/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation
import UIKit

/// Represents the role of the message sender in the conversation.
enum LLMRole: String, Codable {
  case system
  case user
  case assistant
}

/// A standardized message format used across all LLM providers.
struct LLMMessage: Identifiable, Codable {
  var id: String = UUID().uuidString
  var role: LLMRole
  var content: String
  /// Optional image associated with the message (e.g., for multimodal input).
  /// Note: Images are typically not Codable directly, so they are excluded from encoding.
  var image: UIImage?
  
  enum CodingKeys: String, CodingKey {
    case id, role, content
  }
}

/// Standardized errors that can occur during LLM interactions.
enum LLMError: Error {
  case invalidAPIKey
  case networkError(Error)
  case invalidResponse
  case rateLimitExceeded
  case providerError(String)
  case imageProcessingFailed
}

/// The core protocol that all LLM providers must implement.
/// This abstraction allows the app to switch between providers (OpenAI, Anthropic, etc.)
/// without changing the UI or business logic.
protocol LLMProvider {
  /// The unique identifier for this provider (e.g., "openai", "anthropic").
  var id: String { get }
  
  /// The display name for the provider (e.g., "OpenAI GPT-4").
  var name: String { get }
  
  /// Sends a conversation history to the LLM and returns a stream of text chunks.
  /// - Parameters:
  ///   - messages: The conversation history, including the current user query.
  /// - Returns: An AsyncThrowingStream that yields text chunks as they are generated.
  func streamChat(messages: [LLMMessage]) async throws -> AsyncThrowingStream<String, Error>
}

