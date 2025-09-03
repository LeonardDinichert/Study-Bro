import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import StripePaymentSheet

private enum Plan: String, CaseIterable, Identifiable { case monthly, yearly; var id: String { rawValue } }

struct SubscribeView: View {
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var viewModel = SubscriptionViewModel()
    @StateObject private var userViewModel = userManagerViewModel()

    @State private var showAlert = false
    @State private var showCancelConfirm = false
    @State private var plan: Plan = .monthly

    // TODO: Replace with your real display prices (or load from Firestore/RemoteConfig)
    private let monthlyPriceText = "CHF 9.99/mo"
    private let yearlyPriceText  = "CHF 99.99/yr"

    var body: some View {
        NavigationStack {
            Group {
                if let user = userViewModel.user {
                    ScrollView {
                        VStack(spacing: 16) {
                            header(user: user)
                            if user.isPremium == true {
                                premiumActions(user: user)
                            } else {
                                benefitsCard
                                planPicker
                                ctaButton
                            }
                            if let msg = viewModel.statusMessage { Text(msg).foregroundStyle(.blue) }
                        }
                        .padding(20)
                    }
                    .background(backgroundDecor.ignoresSafeArea())
                }
            }
        }
        .presentationDetents([.large])
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Close")
            }
        }
        .onAppear {
            Task { try await userViewModel.loadCurrentUser() }
        }
        .alert("Subscription", isPresented: $showAlert, presenting: viewModel.statusMessage) { _ in } message: { Text($0) }
        .onChange(of: viewModel.statusMessage) {
            _, newMessage in showAlert = newMessage != nil
            if viewModel.statusMessage == "Subscription successful." {
                dismiss()
            }
        }
        .sheet(isPresented: $viewModel.isPaymentSheetPresented) {
            if let sheet = viewModel.paymentSheet {
                PaymentSheetHost(paymentSheet: sheet) { result in
                    viewModel.onPaymentCompletion(result: result)
                }
            }
        }
    }

    @ViewBuilder private func header(user: DBUser) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: user.isPremium == true ? "crown.fill" : "sparkles")
                    .font(.system(size: 28, weight: .semibold))
                    .symbolEffect(.pulse, options: .repeating)
                Text(user.isPremium == true ? "Premium Active" : "Go Premium")
                    .font(.system(.largeTitle, design: .rounded).bold())
            }
            .padding(.vertical, 8)

            Text("Unlock all AI features: smart tutoring, instant summaries, flashcards, OCR notes, and more.")
                .multilineTextAlignment(.center)
                .font(.callout)
                .opacity(0.85)
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(LinearGradient(colors: [.white.opacity(0.6), .white.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 20, y: 10)
    }

    private var benefitsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            benefitRow(icon: "brain.head.profile", title: "AI Tutor", subtitle: "Chat with an expert tailored to your courses")
            benefitRow(icon: "text.book.closed.fill", title: "1‑Tap Summaries", subtitle: "Turn notes & docs into easy study cards")
            benefitRow(icon: "rectangle.on.rectangle.angled", title: "OCR Notes", subtitle: "Scan from camera and auto-organize")
            benefitRow(icon: "bell.badge.fill", title: "Smart Revisions", subtitle: "Spaced repetition reminders that adapt to you")
        }
        .padding(18)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(.white.opacity(0.15))
        )
    }

    private func benefitRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle().fill(.ultraThinMaterial)
                Image(systemName: icon).font(.system(size: 18, weight: .semibold))
            }
            .frame(width: 36, height: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    private var planPicker: some View {
        VStack(spacing: 12) {
            Picker("Plan", selection: $plan) {
                Text("Monthly").tag(Plan.monthly)
                HStack(spacing: 6) {
                    Text("Yearly")
                    Text("Best value").font(.caption2).padding(.horizontal, 6).padding(.vertical, 2)
                        .background(.thinMaterial, in: Capsule())
                }.tag(Plan.yearly)
            }
            .pickerStyle(.segmented)

            HStack(spacing: 12) {
                pricePill(title: "Monthly", price: monthlyPriceText, selected: plan == .monthly)
                pricePill(title: "Yearly", price: yearlyPriceText, selected: plan == .yearly, badge: "Save more")
            }
        }
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
    }

    private func pricePill(title: String, price: String, selected: Bool, badge: String? = nil) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                Text(title).font(.subheadline.weight(.semibold))
                if let b = badge { Text(b).font(.caption2).padding(.horizontal, 6).padding(.vertical, 2).background(.thinMaterial, in: Capsule()) }
            }
            Text(price).font(.title3.weight(.bold))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(selected ? .regularMaterial : .thinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(selected ? .white.opacity(0.35) : .white.opacity(0.15), lineWidth: 1)
        )
    }

    private var ctaButton: some View {
        Button {
            viewModel.subscribe(monthly: plan == .monthly)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                Text(plan == .monthly ? "Start Monthly" : "Start Yearly")
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(LinearGradient(colors: [Color.accentColor.opacity(0.9), Color.accentColor.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 14))
            .foregroundStyle(.white)
        }
        .buttonStyle(.plain)
        .shadow(color: Color.accentColor.opacity(0.35), radius: 18, y: 8)
    }

    @ViewBuilder private func premiumActions(user: DBUser) -> some View {
        VStack(spacing: 14) {
            Text("All AI features unlocked.").font(.headline)
            Text("Enjoy smart revision.")
                .font(.subheadline).foregroundStyle(.secondary)
            if let subId = user.stripeSubscriptionId {
                Button("Manage Subscription") { viewModel.showManage = true }
                Button("Cancel Subscription", role: .destructive) { showCancelConfirm = true }
                    .confirmationDialog("Cancel subscription?", isPresented: $showCancelConfirm) {
                        Button("Confirm Cancel", role: .destructive) { viewModel.cancel(subscriptionId: subId) }
                        Button("Keep Subscription", role: .cancel) {}
                    }
            }
        }
        .padding(18)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(.white.opacity(0.15)))
    }

    private var backgroundDecor: some View {
        ZStack {
            LinearGradient(colors: [Color.blue.opacity(0.25), Color.mint.opacity(0.2), Color.indigo.opacity(0.25)], startPoint: .topLeading, endPoint: .bottomTrailing)
            Circle().fill(Color.white.opacity(0.08)).blur(radius: 40).frame(width: 220, height: 220).offset(x: -120, y: -140)
            Circle().fill(Color.white.opacity(0.06)).blur(radius: 50).frame(width: 260, height: 260).offset(x: 140, y: 220)
        }
    }
}

struct PaymentSheetHost: UIViewControllerRepresentable {
    let paymentSheet: PaymentSheet
    let completion: (PaymentSheetResult) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }
    func makeUIViewController(context: Context) -> UIViewController { UIViewController() }
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        guard !context.coordinator.didPresent else { return }
        context.coordinator.didPresent = true
        paymentSheet.present(from: uiViewController) { result in completion(result) }
    }

    final class Coordinator { var didPresent = false; let parent: PaymentSheetHost; init(_ parent: PaymentSheetHost) { self.parent = parent } }
}

#Preview {
    SubscribeView()
}
