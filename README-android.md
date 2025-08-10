# Android Setup

1. Place `google-services.json` in `android/app/`.
2. Add debug and release SHA-1 fingerprints to Firebase project.
3. Fill placeholders in code:
   - `STRIPE_PUBLISHABLE_KEY` in `StudyBroApp.kt`.
   - `SUBSCRIPTION_BACKEND_URL` in `SubscriptionRepository`.
   - `HUGGINGFACE_API_KEY` and `HUGGINGFACE_MODEL` in `ChatBotViewModel`.
4. Build with `cd android && ./gradlew :app:assembleDebug`.
