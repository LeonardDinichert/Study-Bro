import Foundation
import SwiftUI
import Combine
import AVFoundation
import Vision
import UniformTypeIdentifiers
import UIKit

// MARK: - Core Models

struct Card: Identifiable, Hashable, Codable {
    let id: String
    var front: String
    var back: String
    var imageURL: URL?
    var audioLangCode: String?
    var tags: [String] = []
    var isStarred: Bool = false
}

struct Deck: Identifiable, Codable {
    let id: String
    var title: String
    var cards: [Card]
}

struct UserProfile: Identifiable, Codable { let id: String; var name: String; var photoURL: URL? }
struct Folder: Identifiable, Codable { let id: String; var title: String; var deckIDs: [String] }
struct Classroom: Identifiable, Codable { let id: String; var name: String; var ownerUID: String; var memberUIDs: [String] }

struct Assignment: Identifiable, Codable {
    let id: String
    var classroomID: String
    var deckID: String
    var dueDate: Date
    var requiredMastery: Double // 0..1
}

enum ReviewResult: Int, Codable { case again = 0, hard = 1, good = 2, easy = 3 }

struct SRSState: Codable {
    var ease: Double = 2.5
    var intervalDays: Int = 0
    var repetitions: Int = 0
    var dueDate: Date = .now
}

struct CardSRS: Identifiable, Codable { let id: String; let userID: String; let cardID: String; var state: SRSState; var mastery: Double }
struct StudyLog: Identifiable, Codable { let id: String; let userID: String; let deckID: String; let startedAt: Date; var endedAt: Date?; var grades: [String: ReviewResult] }
struct AudioClip: Identifiable, Codable { let id: String; var url: URL; var duration: TimeInterval }

// MARK: - SRS

func scheduleNext(from s: SRSState, grade: ReviewResult) -> SRSState {
    var st = s
    let q = Double(grade.rawValue)
    st.ease = max(1.3, st.ease + (0.1 - (3 - q) * (0.08 + (3 - q) * 0.02)))
    let cal = Calendar.current
    if grade == .again {
        st.repetitions = 0
        st.intervalDays = 0
        if let due = cal.date(byAdding: .hour, value: 10, to: .now) { st.dueDate = due }
        return st
    }
    st.repetitions += 1
    if st.repetitions == 1 { st.intervalDays = 1 }
    else if st.repetitions == 2 { st.intervalDays = 6 }
    else { st.intervalDays = Int(Double(st.intervalDays) * st.ease).clamped(to: 1...3650) }
    if let due = cal.date(byAdding: .day, value: st.intervalDays, to: .now) { st.dueDate = due }
    return st
}

extension Comparable {
    func clamped(to r: ClosedRange<Self>) -> Self { min(max(self, r.lowerBound), r.upperBound) }
}

// MARK: - TTS + Audio Recording

final class Speaker {
    static let shared = Speaker()
    private let synth = AVSpeechSynthesizer()
    func say(_ text: String, lang: String? = nil) {
        let u = AVSpeechUtterance(string: text)
        if let lang { u.voice = AVSpeechSynthesisVoice(language: lang) }
        synth.speak(u)
    }
}

final class AudioRecorder: NSObject, ObservableObject, AVAudioRecorderDelegate {
    @Published var isRecording = false
    private var rec: AVAudioRecorder?
    func start() throws {
        let sess = AVAudioSession.sharedInstance()
        try sess.setCategory(.playAndRecord, mode: .spokenAudio, options: [.defaultToSpeaker])
        try sess.setActive(true)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".m4a")
        let settings: [String: Any] = [AVFormatIDKey: kAudioFormatMPEG4AAC, AVSampleRateKey: 44100, AVNumberOfChannelsKey: 1]
        rec = try AVAudioRecorder(url: url, settings: settings)
        rec?.delegate = self
        rec?.record()
        isRecording = true
    }
    func stop() { rec?.stop(); isRecording = false }
}

// MARK: - OCR

func recognizeText(from cgImage: CGImage, completion: @escaping ([String]) -> Void) {
    let req = VNRecognizeTextRequest { req, _ in
        let lines = (req.results as? [VNRecognizedTextObservation])?
            .compactMap { $0.topCandidates(1).first?.string } ?? []
        completion(lines)
    }
    req.recognitionLanguages = ["en","de","fr","es"]
    req.usesLanguageCorrection = true
    let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
    try? handler.perform([req])
}

// MARK: - Import

enum ImportError: Error { case malformed }

struct ImportService {
    static func parse(text: String) throws -> [Card] {
        var out: [Card] = []
        let lines = text.split(whereSeparator: { $0.isNewline })
        let delimiters: Set<Character> = [";", "\t", ","]
        for line in lines {
            let cols = line.split(whereSeparator: { delimiters.contains($0) })
            guard cols.count >= 2 else { continue }
            out.append(Card(id: UUID().uuidString, front: String(cols[0]), back: String(cols[1])))
        }
        if out.isEmpty { throw ImportError.malformed }
        return out
    }
}

// MARK: - Engines

final class FlashcardsVM: ObservableObject {
    @Published var flipped = false
    @Published var deck: Deck
    @Published var sessionDone = false

    // immediate session queue of card indices
    @Published private(set) var queue: [Int] = []
    // per-card SRS states (in-memory here; persist to Firestore if needed)
    private var srs: [String: SRSState] = [:]

    #if canImport(UIKit)
    let h = UIImpactFeedbackGenerator(style: .medium)
    #endif

    init(deck: Deck) {
        self.deck = deck
        self.queue = Array(deck.cards.indices)
        self.srs = Dictionary(uniqueKeysWithValues: deck.cards.map { ($0.id, SRSState()) })
    }

    var currentCard: Card? {
        guard let i = queue.first else { return nil }
        return deck.cards[i]
    }

    func mark(_ r: ReviewResult) {
        guard let i = queue.first else { sessionDone = true; return }
        #if canImport(UIKit)
        h.impactOccurred()
        #endif

        // update SRS
        let id = deck.cards[i].id
        if let prev = srs[id] { srs[id] = scheduleNext(from: prev, grade: r) }

        // requeue policy
        _ = queue.removeFirst()
        switch r {
        case .again:
            let pos = min(2, queue.count)
            queue.insert(i, at: pos)         // come back very soon
        case .hard:
            let pos = min(5, queue.count)
            queue.insert(i, at: pos)         // later in the session
        case .good, .easy:
            break                             // learned for this session
        }

        flipped = false
        if queue.isEmpty { sessionDone = true }
    }
}


enum LearnStep { case preview, recall, feedback }

final class LearnEngine: ObservableObject {
    @Published var queue: [Card] = []
    @Published var current: Card?
    @Published var step: LearnStep = .preview
    private var srs: [String: SRSState] = [:]

    func start(with deck: Deck) {
        srs = Dictionary(uniqueKeysWithValues: deck.cards.map { ($0.id, SRSState()) })
        queue = deck.cards.shuffled()
        advance()
    }
    func grade(_ r: ReviewResult) {
        guard let c = current else { return }
        if let old = srs[c.id] { srs[c.id] = scheduleNext(from: old, grade: r) }
        if r == .again || r == .hard { queue.append(c) }
        advance()
    }
    private func advance() { current = queue.isEmpty ? nil : queue.removeFirst(); step = .preview }
}

// MARK: - Question/Test Builders

struct MCQ { let prompt: String; let options: [String]; let correctIndex: Int }

func makeMCQ(from deck: Deck, count: Int = 10) -> [MCQ] {
    var qs: [MCQ] = []
    let cards = deck.cards.shuffled()
    for c in cards.prefix(count) {
        var pool = Array(Set(deck.cards.map { $0.back }).subtracting([c.back]))
        pool.shuffle()
        let distractors = Array(pool.prefix(3))
        let opts = ([c.back] + distractors).shuffled()
        guard let idx = opts.firstIndex(of: c.back) else { continue }
        qs.append(MCQ(prompt: c.front, options: opts, correctIndex: idx))
    }
    return qs
}

enum QuestionKind { case mcq, tf, short }
struct Question { let kind: QuestionKind; let prompt: String; let options: [String]; let correct: Int }

func buildTest(from deck: Deck, items: Int = 20) -> [Question] {
    var out: [Question] = []
    let terms = deck.cards.shuffled()
    for c in terms.prefix(items) {
        var pool = Array(Set(deck.cards.map { $0.back }).subtracting([c.back])); pool.shuffle()
        let choices = ([c.back] + pool.prefix(3)).shuffled()
        if let idx = choices.firstIndex(of: c.back) {
            out.append(.init(kind: .mcq, prompt: c.front, options: choices, correct: idx))
        }
        let truth = Bool.random()
        let shown = truth ? c.back : (pool.randomElement() ?? c.back)
        out.append(.init(kind: .tf, prompt: "\(c.front) → \(shown)", options: ["True","False"], correct: truth ? 0 : 1))
        out.append(.init(kind: .short, prompt: c.front, options: [c.back], correct: 0))
    }
    return out
}

// MARK: - Utilities

func levenshtein(_ a: String, _ b: String) -> Int {
    let a = Array(a.lowercased().trimmingCharacters(in: .whitespacesAndNewlines))
    let b = Array(b.lowercased().trimmingCharacters(in: .whitespacesAndNewlines))
    var dp = Array(repeating: Array(repeating: 0, count: b.count+1), count: a.count+1)
    for i in 0...a.count { dp[i][0] = i }
    for j in 0...b.count { dp[0][j] = j }
    for i in 1...a.count {
        for j in 1...b.count {
            dp[i][j] = min(
                dp[i-1][j] + 1,
                dp[i][j-1] + 1,
                dp[i-1][j-1] + (a[i-1] == b[j-1] ? 0 : 1)
            )
        }
    }
    return dp[a.count][b.count]
}

// MARK: - Views

private struct CardFace: View {
    let text: String
    var body: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(.ultraThinMaterial)
            .overlay(Text(text).multilineTextAlignment(.center).padding(24))
            .frame(maxWidth: .infinity, minHeight: 320, maxHeight: 520)
            .shadow(radius: 8)
    }
}

struct FlashcardStackView: View {
    @StateObject var vm: FlashcardsVM
    init(deck: Deck) { _vm = StateObject(wrappedValue: FlashcardsVM(deck: deck)) }

    @GestureState private var drag: CGSize = .zero

    var body: some View {
        Group {
            if vm.sessionDone || vm.currentCard == nil {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill").font(.system(size: 48))
                    Text("Session complete")
                }
                .padding()
            } else if let card = vm.currentCard {
                ZStack {
                    CardFace(text: vm.flipped ? card.back : card.front)
                        .rotation3DEffect(.degrees(vm.flipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
                }
                .padding()
                .offset(x: drag.width)
                .rotationEffect(.degrees(Double(drag.width / 10)))
                .gesture(
                    DragGesture()
                        .updating($drag) { v, s, _ in s = v.translation }
                        .onEnded { v in
                            withAnimation(.spring()) {
                                if v.translation.width < -80 { vm.mark(.again) }   // swipe left = Again
                                else if v.translation.width > 80 { vm.mark(.good) } // swipe right = Good
                            }
                        }
                )
                .onTapGesture { withAnimation(.spring()) { vm.flipped.toggle() } }
                .toolbar {
                    ToolbarItemGroup(placement: .bottomBar) {
                        Button("Again") { withAnimation(.spring()) { vm.mark(.again) } }
                        Spacer()
                        Button("Hard")  { withAnimation(.spring()) { vm.mark(.hard)  } }
                        Button("Good")  { withAnimation(.spring()) { vm.mark(.good)  } }
                        Button("Easy")  { withAnimation(.spring()) { vm.mark(.easy)  } }
                    }
                }
            }
        }
    }
}


// Learn (adaptive)
struct LearnModeView: View {
    let deck: Deck
    @StateObject var eng = LearnEngine()
    var body: some View {
        Group {
            if let c = eng.current {
                VStack(spacing: 16) {
                    CardFace(text: c.front)
                    if eng.step == .preview {
                        Button("Show answer") { eng.step = .recall }
                    } else {
                        CardFace(text: c.back)
                        HStack {
                            Button("Again") { eng.grade(.again) }
                            Button("Hard") { eng.grade(.hard) }
                            Button("Good") { eng.grade(.good) }
                            Button("Easy") { eng.grade(.easy) }
                        }
                    }
                }.padding()
            } else { Text("Done for now").padding() }
        }
        .task { eng.start(with: deck) }
        .navigationTitle("Learn")
    }
}

// Write (typed answers)
struct WriteModeView: View {
    let deck: Deck
    @State private var i = 0
    @State private var input = ""
    @State private var feedback: String?
    var body: some View {
        VStack(spacing: 16) {
            if deck.cards.indices.contains(i) {
                Text(deck.cards[i].front).font(.title3)
                TextField("Type answer", text: $input).textFieldStyle(.roundedBorder)
                Button("Check") {
                    let target = deck.cards[i].back
                    let d = levenshtein(input, target)
                    let ok = d <= max(1, target.count/10)
                    feedback = ok ? "Correct" : "Expected: \(target)"
                    if ok { i += 1; input = "" }
                }
                if let f = feedback { Text(f) }
            } else { Text("All done") }
        }
        .padding()
        .navigationTitle("Write")
    }
}

// Test (MCQ/TF/Short)
struct TestModeView: View {
    let deck: Deck
    @State private var qs: [Question] = []
    @State private var i = 0
    @State private var score = 0
    @State private var answer = ""
    var body: some View {
        VStack(spacing: 16) {
            if qs.indices.contains(i) {
                let q = qs[i]
                Text(q.prompt).font(.headline)
                switch q.kind {
                case .mcq, .tf:
                    ForEach(q.options.indices, id: \.self) { k in
                        Button(q.options[k]) {
                            if k == q.correct { score += 1 }
                            i += 1
                        }.buttonStyle(.bordered)
                    }
                case .short:
                    TextField("Answer", text: $answer)
                    Button("Submit") {
                        if answer.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == q.options[0].lowercased() { score += 1 }
                        answer = ""; i += 1
                    }
                }
                Text("Score: \(score)/\(qs.count)")
            } else { Text("Final score: \(score)/\(qs.count)") }
        }
        .padding()
        .task { qs = buildTest(from: deck) }
        .navigationTitle("Test")
    }
}

// Match (drag-drop)
struct MatchPairVM: Identifiable { let id = UUID(); let term: String; let def: String }

struct MatchGameView: View {
    let deck: Deck
    @State private var left: [MatchPairVM] = []
    @State private var right: [MatchPairVM] = []
    @State private var matched = Set<UUID>()

    var body: some View {
        HStack {
            List(left) { item in
                Text(item.term).padding().background(.thinMaterial).cornerRadius(8)
                    .onDrag { NSItemProvider(object: item.id.uuidString as NSString) }
            }
            List(right) { item in
                Text(item.def).padding().background(.thinMaterial).cornerRadius(8)
                    .onDrop(of: [UTType.text], isTargeted: nil) { providers in
                        _ = providers.first?.loadObject(ofClass: NSString.self) { obj, _ in
                            if let s = obj as? String, let uuid = UUID(uuidString: s),
                               let leftItem = left.first(where: { $0.id == uuid }) {
                                if leftItem.def == item.def {
                                    DispatchQueue.main.async { matched.insert(item.id) }
                                }
                            }
                        }
                        return true
                    }
                    .overlay(alignment: .trailing) { if matched.contains(item.id) { Image(systemName: "checkmark.circle") } }
            }
        }
        .task {
            let picks = deck.cards.shuffled().prefix(8)
            left = picks.map { .init(term: $0.front, def: $0.back) }.shuffled()
            right = left.shuffled()
        }
        .navigationTitle("Match")
    }
}

// Diagram labeling
struct DiagramPin: Identifiable, Hashable { let id = UUID(); var point: CGPoint; var label: String }

struct DiagramLabelingView: View {
    let image: Image
    @State var pins: [DiagramPin]
    @State private var scale: CGFloat = 1
    @State private var offset: CGSize = .zero

    var body: some View {
        GeometryReader { geo in
            ZStack {
                image
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(scale)
                    .offset(offset)
                    .gesture(DragGesture().onChanged { offset = $0.translation })
                    .simultaneousGesture(MagnificationGesture().onChanged { scale = max(0.8, min(3, $0)) })

                ForEach(pins) { pin in
                    Circle().fill(.blue)
                        .frame(width: 18, height: 18)
                        .overlay(Text("•").font(.caption).foregroundColor(.white))
                        .position(x: pin.point.x * geo.size.width, y: pin.point.y * geo.size.height)
                        .modifier(HelpIfAvailable(text: pin.label))
                }
            }
            .contentShape(Rectangle())
            .modifier(SpatialTapIfAvailable { loc in
                let p = CGPoint(x: loc.x / geo.size.width, y: loc.y / geo.size.height)
                pins.append(.init(point: p, label: ""))
            })
        }
        .navigationTitle("Diagram")
    }
}

// Helpers for availability
struct HelpIfAvailable: ViewModifier {
    let text: String
    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) { content.help(text) } else { content }
    }
}
struct SpatialTapIfAvailable: ViewModifier {
    let onTap: (CGPoint) -> Void
    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content.simultaneousGesture(SpatialTapGesture().onEnded { onTap($0.location) })
        } else {
            content.gesture(DragGesture(minimumDistance: 0).onEnded { onTap($0.location) })
        }
    }
}

// Import UI
struct ImportView: View {
    @State private var src = ""
    @State private var deck: Deck?
    var body: some View {
        VStack {
            Text("Paste CSV/TSV/CSV").font(.headline)
            TextEditor(text: $src).frame(height: 180).border(.secondary)
            Button("Parse") {
                if let cards = try? ImportService.parse(text: src) {
                    deck = Deck(id: UUID().uuidString, title: "Imported", cards: cards)
                }
            }
            if let d = deck { StudyHomeView(deck: d) }
        }
        .padding()
        .navigationTitle("Import")
    }
}

// Live skeleton
struct LiveSession: Identifiable, Codable { let id: String; var deckID: String; var startedAt: Date; var state: String; var teamIDs: [String] }
final class LiveVM: ObservableObject {
    @Published var session: LiveSession?
    func create(for deckID: String) { session = LiveSession(id: UUID().uuidString, deckID: deckID, startedAt: .now, state: "lobby", teamIDs: []) }
    func join(id: String) { session = LiveSession(id: id, deckID: "deck", startedAt: .now, state: "lobby", teamIDs: []) }
    func submit(answer: String) { /* placeholder */ }
}
struct LiveLobbyView: View {
    @StateObject var vm = LiveVM()
    var body: some View {
        VStack(spacing: 12) {
            Text("Quizlet-like Live").font(.headline)
            Button("Create session") { vm.create(for: "deck") }
            Button("Join session") { vm.join(id: "demo") }
            if let s = vm.session { Text("Session: \(s.id) • \(s.state)") }
        }
        .padding()
        .navigationTitle("Live")
    }
}

// Shell
enum StudyMode: Hashable { case flashcards, learn, write, test, match, diagram, live, `import` }

struct StudyHomeView: View {
    let deck: Deck
    var body: some View {
        List {
            NavigationLink("Flashcards") { FlashcardStackView(deck: deck) }
            NavigationLink("Learn (adaptive)") { LearnModeView(deck: deck) }
            NavigationLink("Write") { WriteModeView(deck: deck) }
            NavigationLink("Test") { TestModeView(deck: deck) }
            NavigationLink("Match") { MatchGameView(deck: deck) }
            NavigationLink("Diagram labeling") { DiagramLabelingView(image: Image(systemName: "photo"), pins: []) }
            NavigationLink("Live") { LiveLobbyView() }
            NavigationLink("Import") { ImportView() }
        }
        .navigationTitle(deck.title)
    }
}

// Root
struct ContentView: View {
    var body: some View {
        NavigationStack {
            StudyHomeView(deck: Demo.deck)
        }
    }
}

// Demo
enum Demo {
    static let deck = Deck(
        id: "demo",
        title: "Sample Deck",
        cards: [
            Card(id: "1", front: "Capital of France", back: "Paris"),
            Card(id: "2", front: "2 + 2", back: "4"),
            Card(id: "3", front: "Hello in Spanish", back: "Hola"),
            Card(id: "4", front: "H2O is", back: "Water")
        ]
    )
}

// Preview
#Preview { ContentView() }


import SwiftUI
import PhotosUI
import UIKit

/// One page that links to all study modes and exercises utilities (TTS, recorder, OCR, import).
struct AllFunctionsHubView: View {
    @State private var deck = Deck(
        id: "demo",
        title: "Sample Deck",
        cards: [
            Card(id: "1", front: "Capital of France", back: "Paris"),
            Card(id: "2", front: "2 + 2", back: "4"),
            Card(id: "3", front: "Hello in Spanish", back: "Hola"),
            Card(id: "4", front: "H2O is", back: "Water")
        ]
    )

    @StateObject private var recorder = AudioRecorder()
    @State private var showImport = false
    @State private var showNewSet = false
    @State private var ocrLines: [String] = []
    @State private var pickedItem: PhotosPickerItem?

    var body: some View {
        NavigationStack {
            List {
                Section("Study modes") {
                    NavigationLink("Flashcards") { FlashcardStackView(deck: deck) }
                    NavigationLink("Learn (adaptive)") { LearnModeView(deck: deck) }
                    NavigationLink("Write") { WriteModeView(deck: deck) }
                    NavigationLink("Test") { TestModeView(deck: deck) }
                    NavigationLink("Match") { MatchGameView(deck: deck) }
                    NavigationLink("Diagram labeling") { DiagramLabelingView(image: Image(systemName: "photo"), pins: []) }
                    NavigationLink("Live") { LiveLobbyView() }
                }

                Section("Create & Import") {
                    Button("Create new set") { showNewSet = true }
                    Button("Paste CSV/TSV and import") { showImport = true }
                }

                Section("Audio") {
                    HStack {
                        Button("Speak front") { Speaker.shared.say(deck.cards.first?.front ?? "") }
                        Button("Speak back")  { Speaker.shared.say(deck.cards.first?.back  ?? "") }
                    }
                    HStack {
                        Button(recorder.isRecording ? "Recording…" : "Start record") {
                            do { try recorder.start() } catch { }
                        }.disabled(recorder.isRecording)
                        Button("Stop") { recorder.stop() }.disabled(!recorder.isRecording)
                    }
                }

                Section("OCR") {
                    PhotosPicker(selection: $pickedItem, matching: .images) {
                        Label("Pick image for OCR", systemImage: "doc.text.viewfinder")
                    }
                    if !ocrLines.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("OCR result").font(.subheadline).foregroundStyle(.secondary)
                            ForEach(ocrLines, id: \.self) { Text("• \($0)") }
                        }
                    }
                }
            }
            .navigationTitle(deck.title)
        }
        .sheet(isPresented: $showImport) { ImportSheet(deck: $deck) }
        .sheet(isPresented: $showNewSet) {
            NewSetSheet { newDeck in deck = newDeck }
        }
        .onChange(of: pickedItem) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let ui = UIImage(data: data),
                   let cg = ui.cgImage {
                    recognizeText(from: cg) { lines in
                        DispatchQueue.main.async { ocrLines = lines }
                    }
                }
            }
        }
    }
}


// MARK: - Import sheet

private struct ImportSheet: View {
    @Binding var deck: Deck
    @Environment(\.dismiss) private var dismiss
    @State private var src = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Text("Paste CSV/TSV (front;back)").font(.headline)
                TextEditor(text: $src).frame(minHeight: 200).border(.secondary)
                Button("Parse and replace deck") {
                    if let cards = try? ImportService.parse(text: src), !cards.isEmpty {
                        deck = Deck(id: UUID().uuidString, title: "Imported", cards: cards)
                        dismiss()
                    }
                }
            }
            .padding()
            .navigationTitle("Import")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
        }
    }
}

private struct NewSetSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title: String = ""
    @State private var rows: [EditableCard] = [EditableCard(), EditableCard()]
    let onSave: (Deck) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Title") {
                    TextField("Set title", text: $title)
                }
                Section("Cards") {
                    ForEach($rows) { $row in
                        VStack(spacing: 8) {
                            TextField("Front", text: $row.front)
                            TextField("Back",  text: $row.back)
                            Divider()
                        }
                    }
                    Button {
                        rows.append(EditableCard())
                    } label: {
                        Label("Add card", systemImage: "plus.circle")
                    }
                }
            }
            .navigationTitle("New set")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let cards = rows
                            .filter { !$0.front.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                                      !$0.back.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                            .map { Card(id: UUID().uuidString, front: $0.front, back: $0.back) }
                        guard !title.isEmpty, !cards.isEmpty else { return }
                        onSave(Deck(id: UUID().uuidString, title: title, cards: cards))
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct EditableCard: Identifiable {
    let id = UUID()
    var front: String = ""
    var back: String = ""
}

