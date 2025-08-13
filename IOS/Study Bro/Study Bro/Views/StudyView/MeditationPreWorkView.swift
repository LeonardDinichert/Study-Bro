//
//  MeditationPreWorkView.swift
//  Study Bro
//
//  Created by Léonard Dinichert
//

import SwiftUI
import AVFoundation
import Combine

struct MeditationPreWorkView: View {
    // MARK: – Timer & Quotes
    @State private var timeRemaining = 180
    @State private var currentQuote = ""
    private let quotes = [
        "Be sure that you know all your goals for the first timer, the next one, and for the day.",
        "Breathe in, and out, focus",
        "Stillness is where creativity and solutions are found.",
        "Visualise yourself already working",
        "Think about how proud you will be of yourself when you will have finished this work",
    ]
    
    private let quoteTimer = Timer.publish(every: 15, on: .main, in: .common).autoconnect()
    private let countdownTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()


    // MARK: – Audio & Animation
    @State private var player: AVAudioPlayer?
    @State private var animateGradient = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: – View Control
    @Binding var openMeditationView: Bool

    var body: some View {
        ZStack {
            // MARK: — Animated Gradient Background
            LinearGradient(
                gradient: Gradient(colors: [AppTheme.primaryTint.opacity(0.6), AppTheme.primaryShade.opacity(0.6)]),
                startPoint: animateGradient ? .topLeading : .bottomTrailing,
                endPoint: animateGradient ? .bottomTrailing : .topLeading
            )
            .ignoresSafeArea()
            .animation(reduceMotion ? nil : .easeInOut(duration: 20).repeatForever(autoreverses: true), value: animateGradient)

            VStack(spacing: 30) {
                // MARK: — Countdown Display
                Text(formattedTime)
                    .font(.system(size: 64, weight: .thin, design: .rounded))
                    .foregroundColor(.white)
                    .onReceive(countdownTimer) { _ in
                        guard timeRemaining > 0 else { return }
                        timeRemaining -= 1
                    }

                // MARK: — Random Quote Display
                Text(currentQuote)
                    .font(.title3)
                    .italic()
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                    .padding(.horizontal)
                    .onReceive(quoteTimer) { _ in
                        currentQuote = quotes.randomElement()!
                    }

                HStack(spacing: 40) {
                    // MARK: — Sound Toggle
                    Button(action: toggleSound) {
                        Image(systemName: player?.isPlaying == true ? "speaker.slash.fill" : "speaker.wave.2.fill")
                            .font(.title)
                            .foregroundColor(.white)
                    }

                    // MARK: — Finish Button
                    Button {
                        player?.stop()
                        openMeditationView = false
                    } label: {
                        Text("Finish")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                    }
                }
            }
            .padding()
        }
        .onAppear {
            if !reduceMotion { animateGradient.toggle() }
            configureAudioSession()
            startSound()
        }
        .onChange(of: formattedTime) { oldValue, newValue in
            if oldValue == "00:00" {
                openMeditationView = false
            }
        }
    }

    // MARK: — Formatted Time String
    private var formattedTime: String {
        let m = timeRemaining / 60, s = timeRemaining % 60
        return String(format: "%02d:%02d", m, s)
    }

    // MARK: — Audio Setup & Control
    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: [])
        try? session.setActive(true)
    }

    private func startSound() {
        guard let url = Bundle.main.url(forResource: "relaxing", withExtension: "mp3") else { return }
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.numberOfLoops = -1
            player?.play()
        } catch {
            print("Audio error:", error)
        }
    }

    private func toggleSound() {
        guard let player = player else { return }
        if player.isPlaying { player.pause() }
        else { player.play() }
    }
}

#Preview {
    MeditationPreWorkView(openMeditationView: .constant(true))
}
