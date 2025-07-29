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
    @StateObject private var dataModel = CalendarViewModel()

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
                DayView(
                    date: currentDate,
                    calendar: calendar,
                    tasks: dataModel.tasks(on: currentDate, calendar: calendar),
                    notes: dataModel.notes(on: currentDate, calendar: calendar)
                )
            case .week:
                WeekView(
                    date: currentDate,
                    calendar: calendar,
                    highlights: Set(dataModel.tasks.map { $0.dueDate } + dataModel.notes.flatMap { $0.reminderDates })
                )
            case .month:
                MonthView(
                    date: currentDate,
                    calendar: calendar,
                    highlights: Set(dataModel.tasks.map { $0.dueDate } + dataModel.notes.flatMap { $0.reminderDates })
                )
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
        .task {
            await dataModel.load()
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
    let tasks: [TaskItem]
    let notes: [LearningNote]

    private var formatter: DateFormatter {
        let df = DateFormatter()
        df.dateStyle = .full
        return df
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(formatter.string(from: date))
                    .font(.title.weight(.semibold))
                if tasks.isEmpty && notes.isEmpty {
                    Text("No reminders")
                        .foregroundStyle(.secondary)
                }
                ForEach(tasks) { task in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(task.title)
                                .font(.headline)
                            Text(task.dueDate, style: .time)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                ForEach(notes) { note in
                    HStack {
                        Text(note.text)
                            .font(.headline)
                        Spacer()
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
            .padding()
        }
    }
}

private struct WeekView: View {
    let date: Date
    let calendar: Calendar
    let highlights: Set<Date>

    var body: some View {
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date))!
        let days = (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: startOfWeek) }
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7)) {
            ForEach(days, id: \.self) { day in
                Text(dayNumber(day))
                    .frame(maxWidth: .infinity)
                    .padding(8)
                    .background(highlights.contains { calendar.isDate($0, inSameDayAs: day) } ? Color.orange.opacity(0.3) : (calendar.isDate(day, inSameDayAs: Date()) ? Color.orange.opacity(0.2) : Color.clear))
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
    let highlights: Set<Date>

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
                    .background(highlights.contains { calendar.isDate($0, inSameDayAs: day) } ? Color.orange.opacity(0.3) : (calendar.isDate(day, inSameDayAs: Date()) ? Color.orange.opacity(0.2) : Color.clear))
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
