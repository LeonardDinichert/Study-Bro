import SwiftUI
import FirebaseAuth

struct CardsView: View {
    @StateObject private var viewModel = CardsViewModel()
    @State private var selectedMode: Mode = .flashcards
    @State private var showingCreate = false

    enum Mode: String, CaseIterable {
        case flashcards = "Cards"
        case learn = "Learn"
        case test = "Test"
        case write = "Write"
        case spell = "Spell"
    }

    var body: some View {
        NavigationStack {
            VStack {
                Picker("Mode", selection: $selectedMode) {
                    ForEach(Mode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                switch selectedMode {
                case .flashcards:
                    FlashcardsSubview(viewModel: viewModel)
                case .learn:
                    LearnSubview(viewModel: viewModel)
                case .test:
                    TestSubview(viewModel: viewModel)
                case .write:
                    WriteSubview(viewModel: viewModel)
                case .spell:
                    SpellSubview(viewModel: viewModel)
                }
            }
        }
        .navigationTitle("Cards")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingCreate = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingCreate) {
            CreateSetView(viewModel: viewModel)
        }
        .task { await viewModel.loadSets() }
        .onChange(of: viewModel.isAutoplay) { oldValue, newValue in
            if newValue { viewModel.startAutoplay() } else { viewModel.stopAutoplay() }
        }
    }
}

// MARK: - Flashcards
struct FlashcardsSubview: View {
    @ObservedObject var viewModel: CardsViewModel

    var body: some View {
        VStack(spacing: 24) {
            if let set = viewModel.currentSet, !set.items.isEmpty {
                TabView(selection: $viewModel.currentIndex) {
                    ForEach(Array(set.items.enumerated()), id: \.1.id) { index, item in
                        StudyCardView(card: item)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .automatic))
                .frame(height: 260)

                Text("\(viewModel.currentIndex + 1) / \(set.items.count)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                HStack {
                    Button(action: { viewModel.previousCard() }) {
                        Image(systemName: "chevron.left")
                    }
                    Spacer()
                    Button(action: {
                        viewModel.isAutoplay.toggle()
                        if viewModel.isAutoplay { viewModel.startAutoplay() } else { viewModel.stopAutoplay() }
                    }) {
                        Image(systemName: viewModel.isAutoplay ? "pause.circle" : "play.circle")
                    }
                    Spacer()
                    Button(action: { viewModel.nextCard() }) {
                        Image(systemName: "chevron.right")
                    }
                }
                .font(.title3)
                .padding(.horizontal)

                HStack {
                    Button(action: { viewModel.shuffle() }) {
                        Label("Shuffle", systemImage: "shuffle")
                    }
                    Spacer()
                    Button(action: { Task { await viewModel.toggleStar() } }) {
                        Image(systemName: set.items[viewModel.currentIndex].starred ? "star.fill" : "star")
                    }
                }
                .padding(.horizontal)
            } else {
                Text("No cards available")
            }
        }
        .padding()
    }
}

struct StudyCardView: View {
    let card: StudyCardItem
    @State private var isFlipped = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(radius: 4)
            Text(isFlipped ? card.definition : card.term)
                .font(.title2)
                .padding()
                .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
        }
        .frame(height: 220)
        .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
        .onTapGesture {
            withAnimation(.spring()) { isFlipped.toggle() }
        }
    }
}

// MARK: - Learn
struct LearnSubview: View {
    @ObservedObject var viewModel: CardsViewModel
    @State private var answer: String = ""
    @State private var feedback: String?
    @State private var mastery: [String: Int] = [:]

    private var currentItem: StudyCardItem? {
        guard let set = viewModel.currentSet, !set.items.isEmpty else { return nil }
        return set.items[viewModel.currentIndex]
    }

    var body: some View {
        VStack(spacing: 16) {
            if let card = currentItem {
                Text(card.term)
                    .font(.title)
                TextField("Answer", text: $answer)
                    .textFieldStyle(.roundedBorder)
                if let feedback = feedback {
                    Text(feedback)
                        .foregroundStyle(feedback == "Correct" ? .green : .red)
                }
                Button("Check") {
                    if card.definition.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) == answer.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) {
                        feedback = "Correct"
                        mastery[card.id, default: 0] += 1
                        viewModel.nextCard()
                    } else {
                        feedback = "Incorrect"
                    }
                    answer = ""
                }
                ProgressView(value: Double(mastery[card.id] ?? 0), total: 5)
                    .tint(.orange)
            } else {
                Text("No cards")
            }
        }
        .padding()
    }
}

// MARK: - Test
struct TestSubview: View {
    @ObservedObject var viewModel: CardsViewModel
    @State private var showingResults = false
    @State private var score = 0
    @State private var currentQuestion = 0

    var body: some View {
        VStack(spacing: 16) {
            if showingResults {
                Text("Score: \(score)")
                Button("Restart") {
                    score = 0
                    currentQuestion = 0
                    showingResults = false
                }
            } else {
                if let set = viewModel.currentSet, !set.items.isEmpty {
                    let item = set.items[currentQuestion % set.items.count]
                    Text(item.term)
                        .font(.title)
                    TextField("Answer", text: Binding(get: { "" }, set: { _ in }))
                        .textFieldStyle(.roundedBorder)
                    Button("Next") {
                        score += 1
                        currentQuestion += 1
                        if currentQuestion >= set.items.count { showingResults = true }
                    }
                } else {
                    Text("No cards")
                }
            }
        }
        .padding()
    }
}

// MARK: - Write
struct WriteSubview: View {
    @ObservedObject var viewModel: CardsViewModel
    @State private var text: String = ""
    var body: some View {
        VStack(spacing: 16) {
            if let set = viewModel.currentSet, !set.items.isEmpty {
                let card = set.items[viewModel.currentIndex]
                Text(card.term)
                    .font(.title)
                TextField("Write here", text: $text)
                    .textFieldStyle(.roundedBorder)
                Button("Check") {
                    // simple check
                }
            } else {
                Text("No cards")
            }
        }
        .padding()
    }
}

struct SpellSubview: View {
    @ObservedObject var viewModel: CardsViewModel
    @State private var text: String = ""
    var body: some View {
        VStack(spacing: 16) {
            if let set = viewModel.currentSet, !set.items.isEmpty {
                Text("Spell the word you hear")
                TextField("Type here", text: $text)
                    .textFieldStyle(.roundedBorder)
                Button("Check") {}
            } else {
                Text("No cards")
            }
        }
        .padding()
    }
}

// MARK: - Create Set
struct CreateSetView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: CardsViewModel
    @State private var title: String = ""
    @State private var term: String = ""
    @State private var definition: String = ""
    @State private var items: [StudyCardItem] = []

    var body: some View {
        NavigationStack {
            Form {
                Section("Title") {
                    TextField("Title", text: $title)
                }
                Section("Items") {
                    ForEach(items) { item in
                        VStack(alignment: .leading) {
                            Text(item.term)
                            Text(item.definition)
                                .font(.caption)
                        }
                    }
                    TextField("Term", text: $term)
                    TextField("Definition", text: $definition)
                    Button("Add Item") {
                        let new = StudyCardItem(term: term, definition: definition)
                        items.append(new)
                        term = ""
                        definition = ""
                    }
                }
            }
            .navigationTitle("New Set")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        guard let uid = Auth.auth().currentUser?.uid else { return }
                        let new = StudySet(title: title, owner: uid, items: items)
                        Task {
                            _ = try? await StudySetManager.shared.createSet(new, userId: uid)
                            await viewModel.loadSets()
                            dismiss()
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    CardsView()
}
