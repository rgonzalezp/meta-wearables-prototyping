/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import SwiftUI

struct TypingIndicator: View {
  @State private var numberOfDots = 0
  
  var body: some View {
    HStack(spacing: 4) {
      ForEach(0..<3) { index in
        Circle()
          .frame(width: 8, height: 8)
          .foregroundColor(.gray.opacity(0.6))
          .scaleEffect(numberOfDots == index ? 1.2 : 0.8)
          .animation(
            Animation.easeInOut(duration: 0.5)
              .repeatForever()
              .delay(Double(index) * 0.2),
            value: numberOfDots
          )
      }
    }
    .padding(12)
    .background(Color(.systemGray5))
    .clipShape(RoundedRectangle(cornerRadius: 16))
    .onAppear {
      numberOfDots = 3 // Trigger animation state
    }
  }
}

