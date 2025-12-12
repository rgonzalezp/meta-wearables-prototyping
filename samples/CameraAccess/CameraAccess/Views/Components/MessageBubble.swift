/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import SwiftUI

struct MessageBubble: View {
  let message: LLMMessage

  var body: some View {
    HStack {
      if message.role == .user {
        Spacer()
      }
      
      if message.content.isEmpty && message.role == .assistant {
        TypingIndicator()
      } else {
        Text(message.content)
          .padding(12)
          .background(message.role == .user ? Color.blue : Color(.systemGray5))
          .foregroundColor(message.role == .user ? .white : .primary)
          .clipShape(RoundedRectangle(cornerRadius: 16))
          .frame(maxWidth: 280, alignment: message.role == .user ? .trailing : .leading)
      }
      
      if message.role != .user {
        Spacer()
      }
    }
  }
}

