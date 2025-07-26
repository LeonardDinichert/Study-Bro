import SwiftUI

struct TasksTab: View {
    @StateObject private var viewModel = TasksViewModel()
    @State private var showingAdd = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.tasks) { task in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(task.title)
                            Text(task.dueDate, style: .date)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        Button(action: { Task { await viewModel.toggleCompleted(task) } }) {
                            Image(systemName: task.completed ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(.blue)
                        }
                    }
                    .swipeActions {
                        Button(role: .destructive) { Task { await viewModel.delete(task: task) } } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle("Tasks")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAdd = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .onAppear { Task { await viewModel.loadTasks() } }
            .sheet(isPresented: $showingAdd) {
                AddTaskView(viewModel: viewModel)
            }
        }
    }
}
