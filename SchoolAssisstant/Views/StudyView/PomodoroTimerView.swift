//
//  PomodoroTimerView.swift
//  SchoolAssisstant
//
//  Created by Léonard Dinichert on 27.04.2025.
//
//

import SwiftUI
import UserNotifications
import FirebaseFirestore

struct PomodoroTimerView: View {
    enum Phase { case work, shortBreak, congratulations, longBreak }

    // Durations
    private let workSec = 25 * 60

    private let shortSec = 5 * 60
    private let longSec  = 20 * 60
    private let totalWorkSessions = 4

    // MARK: – State
    @State private var phase: Phase = .work
    @State private var workCount = 0

    @State private var history: [Session] = []
    @State private var lastFetchedDoc: DocumentSnapshot? = nil
    @State private var hasMore = true
    @State private var isFetching = false

    @State private var startTime: Date?
    @State private var accumulated: TimeInterval = 0
    @State private var isRunning = false
    @State private var now = Date()

    @State private var showReset = false
    @State private var showQuit = false
    @State private var showCongrats = false
    @State private var isFocusMode = false
    @State private var showHistoryFullScreen = false

    @Binding var startSession: Bool
    @Binding var userWillStudy: String
    @Binding var userId: String

    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    struct Session: Identifiable, Hashable {
        let id = UUID()
        let date: Date
        let duration: Int
        let type: Phase
        let subject: String
    }

    var body: some View { mainBody }

    private var mainBody: some View {
        NavigationStack {
            Group {
                if isFocusMode { focusView }
                else          { fullView  }
            }
            
            .statusBar(hidden: isFocusMode)
            .animation(.default, value: isFocusMode)
            .navigationTitle("Study Timer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isFocusMode.toggle()
                    } label: {
                        Image(systemName: isFocusMode
                              ? "xmark"
                              : "arrow.up.left.and.arrow.down.right")
                    }
                }
            }
            .navigationDestination(isPresented: $showCongrats) {
                CongratsView {
                    phase = .longBreak
                    resetTimerState()
                    showCongrats = false
                }
            }
            .onReceive(ticker) { tick in
                now = tick
                if isRunning && elapsedSeconds >= currentDuration {
                    print("userid 0 \(userId)")
                    completePhase()
                }
            }
            .alert("Reset Timer?", isPresented: $showReset) {
                Button("Reset", role: .destructive) { resetPhase() }
                Button("Cancel", role: .cancel) { }
            }
            .alert("Quit session?", isPresented: $showQuit) {
                Button("Quit", role: .destructive) { startSession = false }
                Button("Cancel", role: .cancel) { }
            }
            .onChange(of: isRunning, initial: false) { oldValue, newValue in
                if newValue {
                    // started
                    if startTime == nil { startTime = now }
                    scheduleNotification()
                } else {
                    // paused
                    UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
                    if let start = startTime {
                        accumulated += now.timeIntervalSince(start)
                        startTime = nil
                    }
                }
            }
            .onChange(of: phase) {
                resetTimerState()
                if phase != .congratulations {
                    scheduleNotification()
                }
            }
            .onAppear {
                UIApplication.shared.isIdleTimerDisabled = true
                Task {
                    await fetchSessions(initial: true)
                }
            }
            .onDisappear {
                UIApplication.shared.isIdleTimerDisabled = false
            }
            // Removed background with systemBackground; liquid glass container background used instead
        }
        .fullScreenCover(isPresented: $showHistoryFullScreen) {
            HistoryFullScreenView(
                history: history,
                hasMore: hasMore,
                onLoadMore: {
                    Task { await fetchSessions(initial: false) }
                },
                onClose: { showHistoryFullScreen = false }
            )
        }
    }

    // MARK: – Computed
    private var currentDuration: Int {
        switch phase {
        case .work:         return workSec
        case .shortBreak:   return shortSec
        case .longBreak:    return longSec
        case .congratulations: return 0
        }
    }

    private var elapsedSeconds: Int {
        let extra = startTime.map { now.timeIntervalSince($0) } ?? 0
        return Int(accumulated + extra)
    }

    private var progress: Double {
        Double(elapsedSeconds) / Double(max(currentDuration, 1))
    }

    private var timeString: String {
        let rem = max(currentDuration - elapsedSeconds, 0)
        return String(format: "%02d:%02d", rem / 60, rem % 60)
    }

    // MARK: – Views
    private var fullView: some View {
        GeometryReader { geo in
            let isLandscape = geo.size.width > geo.size.height

            Group {
                if isLandscape {
                    // Landscape: timer + controls on left, history on right
                    HStack(spacing: 20) {
                        VStack(spacing: 24) {
                            if phase == .work {
                                Text("Work")
                                    .font(.title2)
                                
                            } else if phase == .shortBreak {
                                Text("Short Break")
                                    .font(.title2)

                            } else if phase == .longBreak {
                                Text("Long Break")
                                    .font(.title2)

                            }
                            timerCard
                                .frame(width: geo.size.width * 0.4,
                                       height: geo.size.width * 0.4)
                            HStack(spacing: 40) {
                                ControlButton(systemName: isRunning ? "pause.fill" : "play.fill") {
                                    isRunning.toggle()
                                }
                                ControlButton(systemName: "gobackward") {
                                    showReset = true
                                }
                            }
                        }
                        .frame(width: geo.size.width * 0.45)
                        
                        Spacer()
                        
                        Divider()
                        
                        // History column
                        VStack(alignment: .leading, spacing: 16) {
                            Text("History")
                                .font(.headline)
                            if history.isEmpty {
                                Text("No sessions yet.")
                                    .foregroundColor(.secondary)
                                    .padding()
                            } else {
                                HistoryListView(history: history, hasMore: hasMore, onLoadMore: {
                                    Task { await fetchSessions(initial: false) }
                                })
                            }
                            Spacer()
                        }
                        .frame(width: geo.size.width * 0.45)
                    }
                    .padding()
                } else {
                    // Portrait: original VStack
                    VStack(spacing: 24) {
                        timerCard.frame(width: 300, height: 300)
                        HStack(spacing: 60) {
                            ControlButton(systemName: isRunning ? "pause.fill" : "play.fill") {
                                isRunning.toggle()
                            }
                            ControlButton(systemName: "gobackward") {
                                showReset = true
                            }
                        }
                        Button("Quit session") { showQuit = true }
                            .font(.callout)
                            .foregroundColor(.red)
                            .padding()
                            .glassEffect()
                        
                        Divider().padding(.vertical, 8)
                        
                        Button(action: { showHistoryFullScreen = true }) {
                            Text("See past sessions")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                        .glassEffect()
                        .padding(.horizontal)

                        Spacer()
                    }
                    .padding(.top)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    private var focusView: some View {
        ZStack {
          
            timerCard.onTapGesture { isFocusMode = false }
        }
        .padding()
    }

    var timerCard: some View {
        ZStack {

            Circle()
                .trim(from: 0, to: progress)
                .stroke(style: .init(lineWidth: 15, lineCap: .round))
                .foregroundColor(.orange)
                .rotationEffect(.degrees(-90))
                .glassEffect()

            VStack(spacing: 4) {
                Text(timeString)
                    .font(.title)
                    .bold()
                if phase == .work {
                    Text("Session \(workCount+1) of \(totalWorkSessions)")
                        .font(.subheadline)
                        .foregroundColor(.orange.opacity(0.8))
                }
                
                Text(userWillStudy)
                    .fontWeight(.semibold)
            }
            .padding(48)
        }
    }

    // MARK: – Actions
    private func resetTimerState() {
        isRunning = false
        accumulated = 0
        startTime = nil
    }

    private func resetPhase() {
        resetTimerState()
        phase = .work
        workCount = 0
        Task {
            await fetchSessions(initial: true)
        }
    }

    private func completePhase() {
        isRunning = false
        if phase == .work {
            workCount += 1
            let end = now
            Task {
                print("UserId 1 is \(userId)")
                do {
                    try await UserManager
                      .shared
                      .addStudySessionRegisteredToUser(
                        userId: userId,
                        studiedSubject: userWillStudy,
                        start: startTime ?? end,
                        end: end
                      )
                    await fetchSessions(initial: true)
                } catch {
                    print("Error adding study session: \(error)")
                }
            }
        }
        switch phase {
        case .work:
            phase = workCount < totalWorkSessions ? .shortBreak : .congratulations
        case .shortBreak:
            phase = .work
        case .congratulations:
            isRunning = false
            showCongrats = true
        case .longBreak:
            workCount = 0
            phase = .work
        }
    }

    private func scheduleNotification() {
        let interval = TimeInterval(max(currentDuration - elapsedSeconds, 0))
        guard interval > 0 else { return }  // Prevent invalid 0-second trigger

        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { _, _ in }

        let content = UNMutableNotificationContent()
        content.title = phase == .work ? "Work completed" : "Time to work"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        center.add(request)
    }

    @MainActor
    private func fetchSessions(initial: Bool) async {
        guard !isFetching else { return }
        isFetching = true
        defer { isFetching = false }
        if initial {
            history = []
            lastFetchedDoc = nil
            hasMore = true
        }
        let db = Firestore.firestore()
        var query = db.collection("users").document(userId).collection("work_sessions")
            .order(by: "session_start", descending: true)
            .limit(to: 10)
        if let last = lastFetchedDoc {
            query = query.start(afterDocument: last)
        }
        do {
            let snap = try await query.getDocuments()
            guard !snap.documents.isEmpty else {
                hasMore = false
                return
            }
            let newSessions = snap.documents.compactMap { doc -> Session? in
                let data = doc.data()
                guard let start = (data["session_start"] as? Timestamp)?.dateValue(),
                      let end = (data["session_end"] as? Timestamp)?.dateValue(),
                      let subject = data["studied_subject"] as? String else { return nil }
                let duration = Int(end.timeIntervalSince(start))
                return Session(date: start, duration: duration, type: .work, subject: subject)
            }
            lastFetchedDoc = snap.documents.last
            history += newSessions
            history = Array(Set(history)).sorted { $0.date > $1.date }
            hasMore = snap.documents.count == 10
        } catch {
            print("Error fetching sessions: \(error)")
            hasMore = false
        }
    }
}

// MARK: – Helpers

private struct ControlButton: View {
    let systemName: String
    let action: ()->Void
    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.largeTitle)
                .foregroundColor(.orange)
                .frame(width: 64, height: 64)
                // iOS 26 liquid glass style for button background
                .glassEffect()
        }
    }
}

private struct HistoryRow: View {
    let session: PomodoroTimerView.Session
    private var fmt: DateFormatter {
        let f = DateFormatter()
        f.dateStyle = .medium; f.timeStyle = .short
        return f
    }
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(session.subject)
                    .font(.subheadline).bold()
                Text(fmt.string(from: session.date))
                    .font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            Text("\(session.duration/60) min")
                .font(.subheadline)
        }
        .padding()
    }
}

private struct HistoryListView: View {
    let history: [PomodoroTimerView.Session]
    let hasMore: Bool
    let onLoadMore: () -> Void
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(history.reversed()) { s in
                    HistoryRow(session: s)
                        .glassEffect()
                }
                if hasMore {
                    Divider()
                    Button("Load more") {
                        onLoadMore()
                    }
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                }
            }
            .padding()
        }
    }
}

private struct HistoryFullScreenView: View {
    let history: [PomodoroTimerView.Session]
    let hasMore: Bool
    let onLoadMore: () -> Void
    let onClose: () -> Void
    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    Spacer()
                    Button(action: onClose) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }
                Text("Session History")
                    .font(.largeTitle).bold()
                    .padding(.bottom)
                HistoryListView(history: history, hasMore: hasMore, onLoadMore: onLoadMore)
                Spacer()
            }
            .background(Color(.systemBackground))
        }
    }
}

private struct CongratsView: View {
    let onContinue: ()->Void
    var body: some View {
        VStack(spacing: 24) {
            Text("🎉 Great job! 🎉")
                .font(.largeTitle).bold()
            Text("You’ve completed four sessions.")
            Button("Take 20 min break", action: onContinue)
                .buttonStyle(.borderedProminent)
        }
        // iOS 26 liquid glass effect for congrats container
        .glassEffect()
        .padding(40)
    }
}
