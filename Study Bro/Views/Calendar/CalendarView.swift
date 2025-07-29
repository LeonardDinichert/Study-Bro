import SwiftUI

enum DisplayMode {
    case day
    case week
    case month
}

struct CalendarView: View {
    @State private var currentDate: Date = Date()
    @State private var displayMode: DisplayMode = .month
    
    private func selectDay(_ date: Date) {
        currentDate = date
        displayMode = .day
    }
    
    var body: some View {
        VStack {
            HStack {
                Button("Day") { displayMode = .day }
                Button("Week") { displayMode = .week }
                Button("Month") { displayMode = .month }
            }
            
            switch displayMode {
            case .day:
                DayView(date: currentDate)
            case .week:
                WeekView(date: currentDate, onDaySelected: selectDay)
            case .month:
                MonthView(date: currentDate, onDaySelected: selectDay)
            }
        }
    }
}

struct WeekView: View {
    let date: Date
    let onDaySelected: ((Date) -> Void)?
    
    private var days: [Date] {
        // Implementation that returns the days in the week of 'date'
        // Stub example:
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: date)!.start
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: startOfWeek) }
    }
    
    var body: some View {
        HStack {
            ForEach(days, id: \.self) { day in
                VStack {
                    Text("\(Calendar.current.component(.day, from: day))")
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    onDaySelected?(day)
                }
            }
        }
    }
}

struct MonthView: View {
    let date: Date
    let onDaySelected: ((Date) -> Void)?
    
    private var days: [Date] {
        // Implementation that returns the days in the month of 'date'
        // Stub example:
        let calendar = Calendar.current
        guard let range = calendar.range(of: .day, in: .month, for: date),
              let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: date)) else {
            return []
        }
        return range.compactMap { calendar.date(byAdding: .day, value: $0 - 1, to: firstDay) }
    }
    
    var body: some View {
        let rows = days.chunked(into: 7)
        VStack {
            ForEach(rows.indices, id: \.self) { rowIndex in
                HStack {
                    ForEach(rows[rowIndex], id: \.self) { day in
                        VStack {
                            Text("\(Calendar.current.component(.day, from: day))")
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onDaySelected?(day)
                        }
                    }
                }
            }
        }
    }
}

struct DayView: View {
    let date: Date
    
    var body: some View {
        Text("Day view for \(date, formatter: dateFormatter)")
    }
}

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter
}()

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        var chunks: [[Element]] = []
        var start = 0
        while start < count {
            let end = Swift.min(start + size, count)
            chunks.append(Array(self[start..<end]))
            start += size
        }
        return chunks
    }
}
