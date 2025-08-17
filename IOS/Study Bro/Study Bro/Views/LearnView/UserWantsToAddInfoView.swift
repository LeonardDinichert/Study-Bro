//
//  UserWantsToAddInfoView.swift
//  Study Bro
//
//  Created by Léonard Dinichert
//

import SwiftUI
import FirebaseAuth
import UserNotifications
import PDFKit
import PhotosUI
import AVFoundation
import VisionKit

struct AddNoteView: View {
    @State private var category = ""
    @State private var learned = ""
    @State private var userCategories: [String] = ["All"]
    
    @State private var selectedDocument: URL? = nil
    @State private var isShowingDocumentPicker = false
    @State private var isShowingScannerSheet = false
    @State private var scannedImageData: Data? = nil
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showCameraPermissionAlert = false
    
    enum Importance: String, CaseIterable, Identifiable {
        case low = "Low", medium = "Medium", high = "High"
        var id: String { rawValue }
    }
    @State private var importance: Importance = .low
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationStack {
            VStack {
                Form {
                    Section(header: Text("Category").font(.callout).foregroundStyle(.secondary)) {
                        Picker("Category", selection: $category) {
                            ForEach(userCategories, id: \.self) { cat in
                                Text(cat).tag(cat)
                            }
                        }
                    }
                    .listRowBackground(RoundedRectangle(cornerRadius: 16).fill(.thinMaterial))

                    Section(header: Text("What did you learn?").font(.callout).foregroundStyle(.secondary)) {
                        TextEditor(text: $learned)
                            .frame(minHeight: 80, maxHeight: 160, alignment: .topLeading)
                            .scrollContentBackground(.hidden)
                            .autocorrectionDisabled(false)
                            .textInputAutocapitalization(.sentences)
                            .padding(.vertical, 6)
                    }
                    .listRowBackground(RoundedRectangle(cornerRadius: 16).fill(.thinMaterial))

                    Section(header: Text("Importance").font(.callout).foregroundStyle(.secondary)) {
                        Picker(selection: $importance) {
                            ForEach(Importance.allCases) { level in
                                Text(level.rawValue).tag(level)
                            }
                        } label: {
                            Label("Importance", systemImage: "flag.fill")
                        }
                        .pickerStyle(.segmented)
                    }
                    .listRowBackground(RoundedRectangle(cornerRadius: 16).fill(.thinMaterial))
                    
                    Section(header: Text("Attach Document").font(.callout).foregroundStyle(.secondary)) {
                        VStack(spacing: 12) {
                            Button {
                                AVCaptureDevice.requestAccess(for: .video) { granted in
                                    DispatchQueue.main.async {
                                        if granted {
                                            isShowingScannerSheet = true
                                        } else {
                                            showCameraPermissionAlert = true
                                        }
                                    }
                                }
                            } label: {
                                Label("Scan Document", systemImage: "doc.text.viewfinder")
                                    .frame(maxWidth: .infinity, minHeight: 44)
                            }
                            .buttonStyle(.bordered)
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                            Button {
                                isShowingDocumentPicker = true
                            } label: {
                                Label("Import PDF", systemImage: "doc.richtext")
                                    .frame(maxWidth: .infinity, minHeight: 44)
                            }
                            .buttonStyle(.bordered)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.vertical, 6)
                        
                        if let url = selectedDocument {
                            HStack {
                                Image(systemName: "doc.fill")
                                    .foregroundColor(.accentColor)
                                Text(url.lastPathComponent)
                                    .font(.subheadline)
                                    .lineLimit(1)
                                Spacer()
                                Button(role: .destructive) {
                                    selectedDocument = nil
                                    scannedImageData = nil
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .listRowBackground(RoundedRectangle(cornerRadius: 16).fill(.thinMaterial))
                }
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 6)
                )
                .padding([.horizontal, .top], 18)
                .animation(.smooth, value: category + learned + String(describing: importance) + (selectedDocument?.absoluteString ?? "") + (scannedImageData != nil ? "1" : "0"))

                Spacer(minLength: 16)

                VStack(spacing: 12) {
                    Button {
                        Task { await save() }
                    } label: {
                        Label("Save Note", systemImage: "tray.and.arrow.down.fill")
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .accentColor.opacity(0.3), radius: 6, x: 0, y: 3)

                    Button(role: .cancel) {
                        isPresented = false
                    } label: {
                        Label("Cancel", systemImage: "xmark")
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(.bordered)
                    .tint(.secondary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .secondary.opacity(0.25), radius: 6, x: 0, y: 3)
                }
                .padding([.horizontal, .bottom], 24)
            }
            .background(.ultraThinMaterial)
            .navigationTitle("Add New Info")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $isShowingDocumentPicker) {
                DocumentPickerView(documentTypes: ["com.adobe.pdf"], onPick: { url in
                    if let url = url {
                        selectedDocument = url
                        scannedImageData = nil
                    }
                    isShowingDocumentPicker = false
                }, onCancel: {
                    isShowingDocumentPicker = false
                })
            }
            .sheet(isPresented: $isShowingScannerSheet) {
                DocumentScannerView { pdfData in
                    if let pdfData = pdfData {
                        let tempDir = FileManager.default.temporaryDirectory
                        let fileURL = tempDir.appendingPathComponent("scannedDocument-\(UUID().uuidString).pdf")
                        do {
                            try pdfData.write(to: fileURL)
                            selectedDocument = fileURL
                            scannedImageData = pdfData
                        } catch {
                            alertMessage = "Failed to save scanned PDF."
                            showAlert = true
                        }
                    }
                    isShowingScannerSheet = false
                } onCancel: {
                    isShowingScannerSheet = false
                }
            }
            .alert(alertMessage, isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            }
            .alert("Camera access is required to scan documents. Please enable it in Settings.", isPresented: $showCameraPermissionAlert) {
                Button("OK", role: .cancel) { }
            }
            .onAppear {
                Task { await loadUserCategories() }
            }
        }
    }
    
    // MARK: - PDF creation helper
    private func createPDFData(from image: UIImage) -> Data {
        let pdfMetaData = [
            kCGPDFContextCreator: "Study Bro",
            kCGPDFContextAuthor: "Study Bro"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageWidth = image.size.width
        let pageHeight = image.size.height
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        return renderer.pdfData { ctx in
            ctx.beginPage()
            image.draw(in: pageRect)
        }
    }
    
    // MARK: - Data
    private func loadUserCategories() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        do {
            let user = try await UserManager.shared.getUser(userId: userId)
            await MainActor.run {
                if let studying = user.isStudying, !studying.isEmpty {
                    self.userCategories = ["All"] + studying
                } else {
                    self.userCategories = ["All"]
                }
                if self.category.isEmpty { self.category = self.userCategories.first ?? "" }
            }
        } catch {
            print("Error loading user categories: \(error)")
        }
    }

    // MARK: - Notifications
    private func getNotificationSettings() async -> UNNotificationSettings {
        await withCheckedContinuation { continuation in
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                continuation.resume(returning: settings)
            }
        }
    }

    private func ensureNotificationAuth() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await getNotificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        default:
            do { return try await center.requestAuthorization(options: [.alert, .sound, .badge]) }
            catch { return false }
        }
    }

    private func scheduleLocalNotification(body: String, at date: Date, id: String) {
        let content = UNMutableNotificationContent()
        content.title = "Study Bro"
        content.body = body
        content.sound = .default

        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let req = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(req)
    }

    private func scheduleImmediate(body: String, id: String) {
        let content = UNMutableNotificationContent()
        content.title = "Study Bro"
        content.body = body
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let req = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(req)
    }

    // MARK: - Save
    func save() async {
        guard let userId = Auth.auth().currentUser?.uid else {
            isPresented = false
            return
        }

        let now = Date()
        let offsets: [(value: Int, component: Calendar.Component)] = [
            (1, .day),          // +1 day
            (4, .day),          // +4 days
            (1, .weekOfYear),   // +1 week
            (1, .month),        // +1 month
            (4, .month)         // +4 months
        ]
        let reminderDates = offsets.compactMap { Calendar.current.date(byAdding: $0.component, value: $0.value, to: now) }
        
        // Upload document if available and get URL string using new StorageManager methods
        var documentURLString: String? = nil
        if let docURL = selectedDocument {
            do {
                let data: Data
                var isPDF = false
                if let scannedData = scannedImageData {
                    data = scannedData
                    isPDF = true
                } else {
                    data = try Data(contentsOf: docURL)
                    isPDF = docURL.pathExtension.lowercased() == "pdf"
                }
                
                if isPDF {
                    // Save PDF using new method savePDF
                    let (path, _) = try await StorageManager.shared.savePDF(data: data, userId: userId)
                    let url = try await StorageManager.shared.getUrlForImage(path: path)
                    documentURLString = url.absoluteString
                } else {
                    // Save image using existing saveImage method with tuple unpack
                    let (path, _) = try await StorageManager.shared.saveImage(data: data, userId: userId)
                    let url = try await StorageManager.shared.getUrlForImage(path: path)
                    documentURLString = url.absoluteString
                }
            } catch {
                await MainActor.run {
                    alertMessage = "Failed to upload document: \(error.localizedDescription)"
                    showAlert = true
                }
                return
            }
        }

        let note = LearningNote(
            id: UUID().uuidString,
            category: category,
            text: learned,
            importance: importance.rawValue,
            reviewCount: 0,
            nextReview: reminderDates.first ?? now,
            createdAt: now,
            documentURL: documentURLString
        )
        
        do {
            // Await and capture the document id returned from addNote
            let noteId = try await NotesManager.shared.addNote(note, userId: userId)
            // id is now saved with the note in Firestore

            if await ensureNotificationAuth(),
               !learned.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                let baseId = "learningnote-\(userId)-\(now.timeIntervalSince1970)"
                scheduleImmediate(body: learned, id: "\(baseId)-now")
                for (idx, date) in reminderDates.enumerated() {
                    scheduleLocalNotification(body: learned, at: date, id: "\(baseId)-\(idx+1)")
                }
            }

            isPresented = false
        } catch {
            print("Failed to save note: \(error)")
        }
    }
}

// MARK: - DocumentPickerView
struct DocumentPickerView: UIViewControllerRepresentable {
    var documentTypes: [String]
    var onPick: (URL?) -> Void
    var onCancel: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: documentTypes.map { UTType($0) }.compactMap { $0 }, asCopy: true)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPickerView

        init(_ parent: DocumentPickerView) {
            self.parent = parent
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.onCancel()
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            parent.onPick(urls.first)
        }
    }
}

struct DocumentScannerView: UIViewControllerRepresentable {
    var onScan: (Data?) -> Void
    var onCancel: () -> Void
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scanner = VNDocumentCameraViewController()
        scanner.delegate = context.coordinator
        return scanner
    }
    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}
    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let parent: DocumentScannerView
        init(_ parent: DocumentScannerView) { self.parent = parent }
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            var images: [UIImage] = []
            for i in 0..<scan.pageCount {
                images.append(scan.imageOfPage(at: i))
            }
            let pdfData = Self.makePDF(from: images)
            controller.dismiss(animated: true) {
                self.parent.onScan(pdfData)
            }
        }
        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            controller.dismiss(animated: true) {
                self.parent.onCancel()
            }
        }
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            controller.dismiss(animated: true) {
                self.parent.onScan(nil)
            }
        }
        static func makePDF(from images: [UIImage]) -> Data? {
            guard !images.isEmpty else { return nil }
            let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: images[0].size))
            return renderer.pdfData { ctx in
                for image in images {
                    ctx.beginPage()
                    image.draw(in: CGRect(origin: .zero, size: image.size))
                }
            }
        }
    }
}

#Preview {
    AddNoteView(isPresented: .constant(true))
}

