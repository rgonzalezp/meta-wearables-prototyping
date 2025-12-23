/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

struct Configuration {
    static var openAIKey: String {
        guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
              let dictionary = NSDictionary(contentsOfFile: path),
              let key = dictionary["OpenAIKey"] as? String else {
            print("WARNING: Secrets.plist not found or OpenAIKey missing.")
            return ""
        }
        return key
    }
    
    static var anthropicKey: String {
        guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
              let dictionary = NSDictionary(contentsOfFile: path),
              let key = dictionary["AnthropicKey"] as? String else {
            print("WARNING: Secrets.plist not found or AnthropicKey missing.")
            return ""
        }
        return key
    }
}

