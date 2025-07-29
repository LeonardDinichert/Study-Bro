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
    @StateObject private var eventsModel = CalendarEventsViewModel()

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
                DayView(date: currentDate, calendar: calendar, model: eventsModel)
            case .week:
                WeekView(date: currentDate, calendar: calendar, model: eventsModel)
            case .month:
                MonthView(date: currentDate, calendar: calendar, model: eventsModel)
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
        .task { await eventsModel.load() }
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
    @ObservedObject var model: CalendarEventsViewModel

    private var formatter: DateFormatter {
        let df = DateFormatter()
        df.dateStyle = .full
        return df
    }

    var body: some View {
        let tasks = model.tasks(on: date)
        let notes = model.notes(on: date)

        ScrollView {
            VStack(spacing: 12) {
                Text(formatter.string(from: date))
                    .font(.title.weight(.semibold))
                    .padding(.bottom, 8)

                if tasks.isEmpty && notes.isEmpty {
                    Text("No reminders")
                        .foregroundStyle(.secondary)
                }

                ForEach(tasks) { task in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(task.title)
                            .font(.headline)
                        Text(task.dueDate, style: .time)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(.ultraThinMaterial)
                    )
                }

                ForEach(notes) { note in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(note.category)
                            .font(.headline)
                        Text(note.text)
                            .font(.subheadline)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(.ultraThinMaterial)
                    )
                }
            }
            .padding()
        }
    }
}

private struct WeekView: View {
    let date: Date
    let calendar: Calendar
    @ObservedObject var model: CalendarEventsViewModel

    var body: some View {
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date))!
        let days = (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: startOfWeek) }
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7)) {
            ForEach(days, id: \.self) { day in
                VStack(spacing: 4) {
                    Text(dayNumber(day))
                        .frame(maxWidth: .infinity)
                        .padding(8)
                        .background(calendar.isDate(day, inSameDayAs: Date()) ? Color.orange.opacity(0.3) : Color.clear)
                        .clipShape(Circle())
                    if model.hasEvents(on: day) {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 6, height: 6)
                    }
                }
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
    @ObservedObject var model: CalendarEventsViewModel

    var body: some View {
        let days = generateDays()
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
            ForEach(dayHeaders, id: \.self) { header in
                Text(header)
                    .font(.subheadline.weight(.bold))
                    .frame(maxWidth: .infinity)
            }
            ForEach(days, id: \.self) { day in
                VStack(spacing: 2) {
                    Text(dayLabel(day))
                        .foregroundStyle(calendar.isDate(day, equalTo: date, toGranularity: .month) ? .primary : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(4)
                        .background(calendar.isDate(day, inSameDayAs: Date()) ? Color.orange.opacity(0.3) : Color.clear)
                        .clipShape(Circle())
                    if model.hasEvents(on: day) {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 5, height: 5)
                    }
                }
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
