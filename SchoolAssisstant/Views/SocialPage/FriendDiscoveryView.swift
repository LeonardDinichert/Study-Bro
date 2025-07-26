import SwiftUI

struct FriendDiscoveryView: View {
    var body: some View {
        VStack {
            Text("Friend Discovery")
                .font(.largeTitle)
                .padding()
            Text("This is a placeholder for finding and adding new friends.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding()
        }
    }
}

#Preview {
    FriendDiscoveryView()
}
