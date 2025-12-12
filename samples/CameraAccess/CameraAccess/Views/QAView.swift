/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import SwiftUI
import Speech
import AVFoundation

struct QAView: View {
  let image: UIImage
  @Environment(\.dismiss) private var dismiss
  
  // Use the shared LLM service. In a real app, this might come from the environment.
  @StateObject private var llmService = LLMService(
    provider: OpenAIProvider(apiKey: Configuration.openAIKey)
  )
  
  @State private var inputText: String = ""
  @FocusState private var isInputFocused: Bool
  
  // Speech Recognition State
  @State private var isRecording = false
  @State private var speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
  @State private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
  @State private var recognitionTask: SFSpeechRecognitionTask?
  @State private var audioEngine = AVAudioEngine()
  @State private var canRecord = false

  var body: some View {
    VStack(spacing: 0) {
      // Header
      HStack {
        Button(action: { dismiss() }) {
          Image(systemName: "chevron.left")
            .font(.system(size: 20, weight: .semibold))
            .foregroundColor(.primary)
        }
        Spacer()
        Text("Ask Question")
          .font(.headline)
        Spacer()
        // Invisible spacer for alignment
        Image(systemName: "chevron.left")
          .font(.system(size: 20, weight: .semibold))
          .foregroundColor(.clear)
      }
      .padding()
      .background(Color(.systemBackground))
      
      ScrollView {
        ScrollViewReader { proxy in
          VStack(spacing: 16) {
            // Display the context image
            Image(uiImage: image)
              .resizable()
              .aspectRatio(contentMode: .fit)
              .frame(height: 200)
              .cornerRadius(12)
              .padding(.horizontal)
            
            LazyVStack(spacing: 12) {
              ForEach(llmService.messages) { message in
                MessageBubble(message: message)
                  .id(message.id)
              }
              
              if let error = llmService.error {
                  Text("Error: \(error)")
                      .foregroundColor(.red)
                      .font(.caption)
              }
            }
            .padding(.horizontal)
          }
          .padding(.vertical)
          .onChange(of: llmService.messages.count) { _ in
            if let lastMessage = llmService.messages.last {
              withAnimation {
                proxy.scrollTo(lastMessage.id, anchor: .bottom)
              }
            }
          }
        }
      }
      
      // Input Area
      VStack(spacing: 0) {
        Divider()
        HStack(spacing: 12) {
          TextField("Type a message...", text: $inputText)
            .textFieldStyle(.roundedBorder)
            .focused($isInputFocused)
            .submitLabel(.send)
            .disabled(isRecording)
            .onSubmit(sendMessage)
          
          Button(action: toggleRecording) {
            Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
              .font(.system(size: 32))
              .foregroundColor(isRecording ? .red : .gray)
          }
          .disabled(!canRecord)
          .opacity(canRecord ? 1.0 : 0.5)

          Button(action: sendMessage) {
            Image(systemName: "arrow.up.circle.fill")
              .font(.system(size: 32))
              .foregroundColor((inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isRecording || llmService.isGenerating) ? .gray : .blue)
          }
          .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isRecording || llmService.isGenerating)
        }
        .padding()
        .background(Color(.systemBackground))
      }
    }
    .background(Color(.systemGroupedBackground))
    .navigationBarHidden(true)
    .onTapGesture {
      isInputFocused = false
    }
    .onAppear {
      requestSpeechAuthorization()
    }
    .onDisappear {
      if isRecording {
        stopRecording()
      }
    }
  }
  
  private func sendMessage() {
    let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !text.isEmpty else { return }
    
    // Clear input immediately
    let textToSend = text
    inputText = ""
    
    Task {
      await llmService.sendMessage(textToSend, image: image)
    }
  }
  
  // MARK: - Speech Recognition
  
  private func requestSpeechAuthorization() {
    SFSpeechRecognizer.requestAuthorization { authStatus in
      Task { @MainActor in
        canRecord = authStatus == .authorized
      }
    }
  }
  
  private func toggleRecording() {
    if isRecording {
      stopRecording()
    } else {
      startRecording()
    }
  }
  
  private func startRecording() {
    // Cancel existing task if any
    if recognitionTask != nil {
      recognitionTask?.cancel()
      recognitionTask = nil
    }
    
    let audioSession = AVAudioSession.sharedInstance()
    do {
      try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
      try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
    } catch {
      print("Audio session properties weren't set because of an error.")
    }
    
    recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
    
    let inputNode = audioEngine.inputNode
    
    guard let recognitionRequest = recognitionRequest else {
      fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
    }
    
    recognitionRequest.shouldReportPartialResults = true
    
    // Clear input text when starting new recording
    inputText = ""
    
    recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
      var isFinal = false
      
      if let result = result {
        inputText = result.bestTranscription.formattedString
        isFinal = result.isFinal
      }
      
      if error != nil || isFinal {
        self.audioEngine.stop()
        inputNode.removeTap(onBus: 0)
        
        self.recognitionRequest = nil
        self.recognitionTask = nil
        
        self.isRecording = false
      }
    }
    
    let recordingFormat = inputNode.outputFormat(forBus: 0)
    inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
      self.recognitionRequest?.append(buffer)
    }
    
    audioEngine.prepare()
    
    do {
      try audioEngine.start()
      isRecording = true
    } catch {
      print("audioEngine couldn't start because of an error.")
    }
  }
  
  private func stopRecording() {
    audioEngine.stop()
    recognitionRequest?.endAudio()
    isRecording = false
    
    // Deactivate audio session
    try? AVAudioSession.sharedInstance().setActive(false)
  }
}
