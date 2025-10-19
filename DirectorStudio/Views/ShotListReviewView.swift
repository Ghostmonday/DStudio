//
//  ShotListReviewView.swift
//  DirectorStudio
//
//  SwiftUI View for reviewing and editing shot lists
//  Allows users to approve, modify, or reject generated segments
//

import SwiftUI

struct ShotListReviewView: View {
    let segments: [PromptSegment]
    let totalDuration: TimeInterval
    let estimatedCost: Decimal
    
    @State private var editedSegments: [PromptSegment]
    @State private var selectedSegment: PromptSegment?
    
    let onApprove: ([PromptSegment]) -> Void
    let onReject: (String) -> Void
    
    init(
        segments: [PromptSegment],
        totalDuration: TimeInterval,
        estimatedCost: Decimal,
        onApprove: @escaping ([PromptSegment]) -> Void,
        onReject: @escaping (String) -> Void
    ) {
        self.segments = segments
        self.totalDuration = totalDuration
        self.estimatedCost = estimatedCost
        self.onApprove = onApprove
        self.onReject = onReject
        self._editedSegments = State(initialValue: segments)
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Summary Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Shot List")
                            .font(.title2)
                            .bold()
                        Spacer()
                        Text("\(editedSegments.count) shots")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Label(formatDuration(totalDuration), systemImage: "clock")
                        Spacer()
                        Label("\(estimatedCost) credits", systemImage: "dollarsign.circle")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding()
                
                // Segment List
                List {
                    ForEach(editedSegments.indices, id: \.self) { index in
                        SegmentRow(
                            segment: editedSegments[index],
                            onTap: { selectedSegment = editedSegments[index] },
                            onDelete: {
                                editedSegments.remove(at: index)
                            }
                        )
                    }
                    .onMove { from, to in
                        editedSegments.move(fromOffsets: from, toOffset: to)
                    }
                }
                .listStyle(.plain)
                
                // Action Buttons
                HStack(spacing: 16) {
                    Button("Reject") {
                        onReject("User rejected shot list")
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                    
                    Button("Approve & Generate") {
                        onApprove(editedSegments)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                EditButton()
            }
            .sheet(item: $selectedSegment) { segment in
                SegmentEditorView(segment: segment) { edited in
                    if let index = editedSegments.firstIndex(where: { $0.index == segment.index }) {
                        editedSegments[index] = edited
                    }
                }
            }
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct SegmentRow: View {
    let segment: PromptSegment
    let onTap: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Shot \(segment.index + 1)")
                        .font(.headline)
                    
                    if let sceneType = segment.sceneType {
                        Text(sceneType.displayName)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(4)
                    }
                }
                
                Text(segment.text)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack {
                    Label("\(String(format: "%.1f", segment.estimatedDuration))s", systemImage: "clock")
                    if let shotType = segment.suggestedShotType {
                        Label(shotType.displayName, systemImage: "camera")
                    }
                }
                .font(.caption2)
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

struct SegmentEditorView: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var editedSegment: PromptSegment
    let onSave: (PromptSegment) -> Void
    
    init(segment: PromptSegment, onSave: @escaping (PromptSegment) -> Void) {
        self._editedSegment = State(initialValue: segment)
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Prompt") {
                    TextEditor(text: $editedSegment.text)
                        .frame(minHeight: 100)
                }
                
                Section("Duration") {
                    Stepper(
                        "Duration: \(String(format: "%.1f", editedSegment.estimatedDuration))s",
                        value: $editedSegment.estimatedDuration,
                        in: 1...30,
                        step: 0.5
                    )
                }
                
                Section("Shot Type") {
                    Picker("Type", selection: $editedSegment.suggestedShotType) {
                        Text("None").tag(nil as PromptSegment.ShotType?)
                        ForEach([
                            PromptSegment.ShotType.wideShot,
                            .mediumShot,
                            .closeup,
                            .extremeCloseup,
                            .overTheShoulder
                        ], id: \.self) { type in
                            Text(type.displayName).tag(type as PromptSegment.ShotType?)
                        }
                    }
                }
                
                Section("Scene Type") {
                    Picker("Type", selection: $editedSegment.sceneType) {
                        Text("None").tag(nil as PromptSegment.SceneType?)
                        ForEach([
                            PromptSegment.SceneType.establishing,
                            .action,
                            .dialogue,
                            .transition,
                            .montage
                        ], id: \.self) { type in
                            Text(type.displayName).tag(type as PromptSegment.SceneType?)
                        }
                    }
                }
                
                Section("Pacing") {
                    TextField("Pacing", text: $editedSegment.pacing)
                }
                
                Section("Transition Hint") {
                    TextField("Transition", text: Binding(
                        get: { editedSegment.transitionHint ?? "" },
                        set: { editedSegment.transitionHint = $0.isEmpty ? nil : $0 }
                    ))
                }
            }
            .navigationTitle("Edit Shot \(editedSegment.index + 1)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(editedSegment)
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ShotListReviewView(
        segments: [
            PromptSegment(
                index: 0,
                text: "A young woman walks through a bustling city street, her eyes scanning the crowd.",
                estimatedDuration: 5.0,
                sceneType: .establishing,
                suggestedShotType: .wideShot,
                pacing: "moderate",
                transitionHint: "fade in"
            ),
            PromptSegment(
                index: 1,
                text: "She stops at a coffee shop window, her reflection showing determination.",
                estimatedDuration: 3.0,
                sceneType: .action,
                suggestedShotType: .closeup,
                pacing: "slow",
                transitionHint: "cut"
            )
        ],
        totalDuration: 8.0,
        estimatedCost: 16.0,
        onApprove: { _ in },
        onReject: { _ in }
    )
}
