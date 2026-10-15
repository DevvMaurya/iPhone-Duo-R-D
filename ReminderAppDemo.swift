//
//  ListingView.swift
//  FirstDUO
//
//  Created by Dev Maurya on 15/10/26.
//
import SwiftUI

struct ListingView: View {
    @StateObject private var viewModel = ListingViewModel()
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @FocusState private var isFocused: Bool
    
    @State private var isComposing = false
    @State private var addCount = 0
    @Namespace private var glassNS
    
    private var doneCount: Int { viewModel.itemArray.filter { $0.isDone }.count }
    private var totalCount: Int { viewModel.itemArray.count }
    private var progress: Double {
        totalCount == 0 ? 0 : Double(doneCount) / Double(totalCount)
    }
    private var trimmed: String {
        viewModel.newTask.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    private var canAdd: Bool { !trimmed.isEmpty }
    
    var body: some View {
        ZStack {
            AnimatedMeshBackground()
            
            if horizontalSizeClass == .regular {
                splitLayout
            } else {
                portraitLayout
            }
        }
        .contentShape(Rectangle())          // makes empty space tappable
        .onTapGesture {
            isFocused = false               // dismisses the keyboard
        }
        .sensoryFeedback(.success, trigger: addCount)
        .animation(.bouncy, value: totalCount)
        .animation(.bouncy, value: isComposing)
    }
    
    // MARK: - Layouts
    
    /// Compact width: list on top, composer pinned at the bottom.
    private var portraitLayout: some View {
        VStack(spacing: 16) {
            header
            content
        }
        .frame(maxWidth: 640)
        .padding(.horizontal)
        .padding(.top, 8)
        .safeAreaInset(edge: .bottom) { composer }
    }
    
    /// Regular width: task list on the left, big input panel on the right.
    private var splitLayout: some View {
        HStack(alignment: .top, spacing: 24) {
            VStack(spacing: 16) {
                header
                content
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            bigComposer
                .frame(width: 380)
                .frame(maxHeight: .infinity)
        }
        .padding()
    }
    
    
    // MARK: - Header
    
    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Task Breaker")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                
                Text("\(doneCount) of \(totalCount) done")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText())
            }
            
            Spacer()
            
            ProgressRing(progress: progress)
                .frame(width: 60, height: 60)
        }
        .padding(.horizontal, 4)
    }
    
    // MARK: - Content
    
    @ViewBuilder
    private var content: some View {
        if viewModel.itemArray.isEmpty {
            emptyState
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.itemArray, id: \.uid) { item in
                        TaskCell(item: item) {
                            viewModel.toggleDone(data: item)
                        }
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.8).combined(with: .opacity),
                            removal: .move(edge: .trailing).combined(with: .opacity)
                        ))
                    }
                }
                .padding(.vertical, 8)
            }
            .scrollIndicators(.hidden)
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "sparkles")
                .font(.system(size: 56))
                .foregroundStyle(.tint)
                .symbolEffect(.pulse, options: .repeating)
            
            Text("Nothing here yet")
                .font(.title3.bold())
            
            Text("Tap + to break down your first task")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .transition(.scale.combined(with: .opacity))
    }
    
    // MARK: - Portrait composer (compact button that expands)
    
    private var composer: some View {
        GlassEffectContainer(spacing: 12) {
            HStack(alignment: .bottom, spacing: 12) {
                if isComposing {
                    inputField
                        .transition(.opacity)
                }
                actionButton
            }
        }
        .frame(maxWidth: 640)
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
    
    private var inputField: some View {
        HStack(spacing: 8) {
            TextField("Enter a task...", text: $viewModel.newTask, axis: .vertical)
                .lineLimit(1...4)
                .focused($isFocused)
                .padding(.leading, 16)
                .padding(.trailing, viewModel.newTask.isEmpty ? 16 : 0)
                .padding(.vertical, 14)
            
            if !viewModel.newTask.isEmpty {
                Button {
                    withAnimation(.bouncy) {
                        viewModel.newTask = ""
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .padding(.trailing, 12)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 26))
        .glassEffectID("composer", in: glassNS)
        .frame(maxWidth: .infinity)
    }
    
    private var actionButton: some View {
        Button(action: handleAction) {
            Image(systemName: actionSymbol)
                .font(.system(size: 22, weight: .semibold))
                .contentTransition(.symbolEffect(.replace))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .glassEffect(.regular.tint(actionTint).interactive(), in: .circle)
                .glassEffectID("action", in: glassNS)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Landscape composer (large panel)
    
    private var bigComposer: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("New Task")
                .font(.title2.bold())
            
            ZStack(alignment: .topLeading) {
                TextEditor(text: $viewModel.newTask)
                    .scrollContentBackground(.hidden)
                    .font(.title3)
                    .focused($isFocused)
                    .padding(12)
                
                if viewModel.newTask.isEmpty {
                    Text("Describe your task...")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 17)
                        .padding(.vertical, 20)
                        .allowsHitTesting(false)
                }
            }
            .frame(maxHeight: .infinity)
            .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 28))
            
            HStack {
                Button("Clear") {
                    withAnimation(.bouncy) { viewModel.newTask = "" }
                }
                .buttonStyle(.glass)
                .disabled(viewModel.newTask.isEmpty)
                
                Spacer()
                
                Button(action: addTask) {
                    Label("Add Task", systemImage: "arrow.up")
                        .font(.headline)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.glassProminent)
                .tint(.green)
                .disabled(!canAdd)
            }
        }
        .padding(20)
    }
    
    // MARK: - Actions
    
    private func handleAction() {
        if !isComposing {
            withAnimation(.bouncy) { isComposing = true }
            Task {
                try? await Task.sleep(for: .milliseconds(300))
                isFocused = true
            }
        } else if canAdd {
            addTask()
        } else {
            withAnimation(.bouncy) { isComposing = false }
            isFocused = false
        }
    }
    
    private func addTask() {
        guard canAdd else { return }
        viewModel.addNewTask(data: DataModel(title: trimmed, isDone: false))
        withAnimation(.bouncy) {
            viewModel.newTask = ""
        }
        addCount += 1
    }
    
    private var actionSymbol: String {
        guard isComposing else { return "plus" }
        return canAdd ? "arrow.up" : "xmark"
    }
    
    private var actionTint: Color {
        guard isComposing else { return .blue }
        return canAdd ? .green : .gray
    }
}

// MARK: - Progress ring

struct ProgressRing: View {
    var progress: Double
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(.secondary.opacity(0.2), lineWidth: 6)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(colors: [.blue, .purple, .pink, .blue], center: .center),
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.bouncy, value: progress)
            
            Text("\(Int(progress * 100))%")
                .font(.caption2.bold())
                .contentTransition(.numericText())
        }
        .padding(6)
        .glassEffect(.regular, in: .circle)
    }
}

// MARK: - Task cell
struct TaskCell: View {
    @ObservedObject var item: DataModel
    var onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 14) {
                Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(item.isDone ? .green : .secondary)
                    .contentTransition(.symbolEffect(.replace))
                    .symbolEffect(.bounce, value: item.isDone)
                
                Text(item.title ?? "")
                    .font(.body.weight(.medium))
                    .strikethrough(item.isDone)
                    .foregroundStyle(item.isDone ? .secondary : .primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)
            .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 22))
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: item.isDone)
        .scrollTransition { content, phase in
            content
                .opacity(phase.isIdentity ? 1 : 0.5)
                .scaleEffect(phase.isIdentity ? 1 : 0.92)
        }
    }
}

// MARK: - Animated background

struct AnimatedMeshBackground: View {
    var body: some View {
        TimelineView(.animation) { context in
            let t = Float(context.date.timeIntervalSinceReferenceDate)
            let wobbleX = sin(t * 0.6) * 0.12
            let wobbleY = cos(t * 0.45) * 0.12
            
            MeshGradient(
                width: 3,
                height: 3,
                points: [
                    SIMD2<Float>(0, 0), SIMD2<Float>(0.5 + wobbleX, 0), SIMD2<Float>(1, 0),
                    SIMD2<Float>(0, 0.5 + wobbleY), SIMD2<Float>(0.5, 0.5 + wobbleY), SIMD2<Float>(1, 0.5 - wobbleY),
                    SIMD2<Float>(0, 1), SIMD2<Float>(0.5 - wobbleX, 1), SIMD2<Float>(1, 1)
                ],
                colors: [
                    .indigo, .purple, .blue,
                    .purple, .pink, .cyan,
                    .blue, .indigo, .purple
                ]
            )
        }
        .opacity(0.35)
        .ignoresSafeArea()
    }
}
