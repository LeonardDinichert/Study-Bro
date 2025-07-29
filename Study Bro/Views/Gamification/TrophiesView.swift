import SwiftUI

struct TrophiesView: View {
    
    @StateObject private var viewModel = TrophiesViewModel()
    
    var body: some View {
        VStack {
            
            Text("Your trophies")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.primary)
            
            if viewModel.trophies.isEmpty {
                Text("No trophies yet")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.trophies, id: \.self) { trophy in
                    VStack {
                        
                        if trophy == "10_day_streak" {
                            
                            Image("10DaysStreakTrophie")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                            
                        } else if trophy == "15_day_streak" {
                            Image("15DaysStreakTrophie")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)

                        } else if trophy == "30_day_streak" {
                            Image("30DaysStreakTrophie")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                            
                        

                        }
                        
                        Text(trophy.replacingOccurrences(of: "_", with: " "))
                    }
                }
            }
        }
        .onAppear {
            Task {
                await viewModel.load()
            }
        }
    }
}

#Preview {
    TrophiesView()
}
