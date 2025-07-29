//
//  DetailNoteView.swift
//  SchoolAssisstant
//
//  Created by Léonard Dinichert on 28.07.2025.
//

import SwiftUI
import Charts
import Foundation

struct DetailNoteView: View {
    
    let note: LearningNote
    
    @State private var wordForCount: String = ""
    
    var body: some View {
        ZStack {
            Rectangle().fill(.ultraThinMaterial).ignoresSafeArea()
            VStack(spacing: 32) {
                
                // Category Section
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Note category :")
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(.primary)
                        Spacer()
                        Text(note.category)
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(.primary)
                            .padding(.trailing)
                        
                    }
                }
                .padding()
                .background(.regularMaterial)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 3)
                
                // Reminder Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("What you have to remember :")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(note.text)
                        .foregroundStyle(.primary)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                }
                .padding()
                .background(.regularMaterial)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 3)
                
                // Review Schedule Graph Section
                VStack(spacing: 12) {
                    Text("Review Schedule Graph")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.primary)
                        .padding(.top, 4)
                    
                    HStack(spacing: 2) {
                        Text("You remembered this note")
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                        Text("\(wordForCount)")
                            .fontWeight(.semibold)
                    }
                    
                    GeometryReader { geometry in
                        let width = geometry.size.width
                        let height: CGFloat = 180
                        let points = 5
                        let spacing = width / CGFloat(points - 1)
                        let labels = ["1st", "2nd", "3rd", "4th", "5th"]
                        
                        return ZStack {
                            // Draw base line
                            Path { path in
                                path.move(to: CGPoint(x: 0, y: height/2))
                                path.addLine(to: CGPoint(x: width, y: height/2))
                            }
                            .stroke(Color.secondary.opacity(0.5), lineWidth: 2)
                            
                            // Draw labels
                            ForEach(0..<labels.count, id: \.self) { idx in
                                Text(labels[idx])
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .labelStyle(.titleAndIcon)
                                    .position(x: CGFloat(idx) * spacing, y: height/2 + 28)
                            }
                        }
                        .frame(height: height)
                    }
                    .frame(height: 200)
                    .padding(.horizontal)
                    .animation(.bouncy, value: [note.reminder_1, note.reminder_2, note.reminder_3, note.reminder_4, note.reminder_5])
                }
                .padding()
                .background(.regularMaterial)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 3)
                .contentMargins(1)
                
                // Description Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("The forgetting curve illustrates how memory retention declines over time when there are no attempts to review information. The horizontal axis represents days since the initial learning or any subsequent review, and the vertical axis shows the percentage of information retained. Spacing these reviews farther apart over time optimizes long-term retention by slowing the rate of forgetting with each repetition.")
                        .font(.caption)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                        .foregroundStyle(.secondary)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding()
                .background(.regularMaterial)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 3)
                
                Spacer()
                    .frame(maxHeight: .infinity, alignment: .bottom)
            }
            .padding()
            
        }
        .onAppear(perform: {
            // Compute how many reminders are true, in order
            let reminders = [note.reminder_1, note.reminder_2, note.reminder_3, note.reminder_4, note.reminder_5]
            let count = reminders.prefix { $0 }.count
            var wordForCount1: String
            switch count {
            case 1: wordForCount1 = "once"
            case 2: wordForCount1 = "twice"
            case 3: wordForCount1 = "three times"
            case 4: wordForCount1 = "four times"
            case 5: wordForCount1 = "five times"
            default: wordForCount1 = "never"
            }
            wordForCount = wordForCount1
        })
    }
}

#Preview {
    DetailNoteView(note: LearningNote(
        category: "Sample Category",
        text: "This is a sample note for preview.",
        importance: "High",
        reviewCount: 2,
        nextReview: Date(),
        createdAt: Date(),
        reminder_1: true,
        reminder_2: false,
        reminder_3: false,
        reminder_4: false,
        reminder_5: false
    ))
}
