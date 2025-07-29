import SwiftUI

struct CalendarView: View {
    enum DisplayMode: String, CaseIterable, Identifiable {
        case day = "Day"
        case week = "Week"
        case month = "Month"

        var id: Self { self }
    }

    @State private var displayMode: DisplayMode = .month
    @State private var currentDate: Date = Date()

    private var calendar: Calendar {
        var cal = Calendar.current
        cal.firstWeekday = 2 // Monday
        return cal
    }

    var body: some View {
        VStack(spacing: 16) {
            Picker("Mode", selection: $displayMode) {
                ForEach(DisplayMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding([.horizontal, .top])

            switch displayMode {
            case .day:
                DayView(date: currentDate, calendar: calendar)
            case .week:
                WeekView(date: currentDate, calendar: calendar)
            case .month:
                MonthView(date: currentDate, calendar: calendar)
            }

            Spacer()
        }
        .navigationTitle("Calendar")
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button(action: previous) {
                    Image(systemName: "chevron.left")
                }
                Button(action: next) {
                    Image(systemName: "chevron.right")
                }
            }
        }
    }

    private func previous() {
        switch displayMode {
        case .day:
            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
        case .week:
            currentDate = calendar.date(byAdding: .weekOfYear, value: -1, to: currentDate) ?? currentDate
        case .month:
            currentDate = calendar.date(byAdding: .month, value: -1, to: currentDate) ?? currentDate
        }
    }

    private func next() {
        switch displayMode {
        case .day:
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        case .week:
            currentDate = calendar.date(byAdding: .weekOfYear, value: 1, to: currentDate) ?? currentDate
        case .month:
            currentDate = calendar.date(byAdding: .month, value: 1, to: currentDate) ?? currentDate
        }
    }
}

private struct DayView: View {
    let date: Date
    let calendar: Calendar

    private var formatter: DateFormatter {
        let df = DateFormatter()
        df.dateStyle = .full
        return df
    }

    var body: some View {
        Text(formatter.string(from: date))
            .font(.title.weight(.semibold))
            .padding()
    }
}

private struct WeekView: View {
    let date: Date
    let calendar: Calendar

    var body: some View {
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date))!
        let days = (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: startOfWeek) }
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7)) {
            ForEach(days, id: \.self) { day in
                Text(dayNumber(day))
                    .frame(maxWidth: .infinity)
                    .padding(8)
                    .background(calendar.isDate(day, inSameDayAs: Date()) ? Color.orange.opacity(0.3) : Color.clear)
                    .clipShape(Circle())
            }
        }
        .padding()
    }

    private func dayNumber(_ date: Date) -> String {
        String(calendar.component(.day, from: date))
    }
}

private struct MonthView: View {
    let date: Date
    let calendar: Calendar

    var body: some View {
        let days = generateDays()
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
            ForEach(dayHeaders, id: \.self) { header in
                Text(header)
                    .font(.subheadline.weight(.bold))
                    .frame(maxWidth: .infinity)
            }
            ForEach(days, id: \.self) { day in
                Text(dayLabel(day))
                    .foregroundStyle(calendar.isDate(day, equalTo: date, toGranularity: .month) ? .primary : .secondary)
                    .frame(maxWidth: .infinity)
                    .padding(4)
                    .background(calendar.isDate(day, inSameDayAs: Date()) ? Color.orange.opacity(0.3) : Color.clear)
                    .clipShape(Circle())
            }
        }
        .padding()
    }

    private var dayHeaders: [String] {
        let symbols = calendar.shortWeekdaySymbols
        let index = calendar.firstWeekday - 1
        return Array(symbols[index...] + symbols[..<index])
    }

    private func dayLabel(_ date: Date) -> String {
        String(calendar.component(.day, from: date))
    }

    private func generateDays() -> [Date] {
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
        let firstWeekday = calendar.component(.weekday, from: startOfMonth)
        let offset = (firstWeekday - calendar.firstWeekday + 7) % 7
        let daysInGrid = 42
        return (0..<daysInGrid).compactMap { index in
            calendar.date(byAdding: .day, value: index - offset, to: startOfMonth)
        }
    }
}

#Preview {
    NavigationStack {
        CalendarView()
    }
}
