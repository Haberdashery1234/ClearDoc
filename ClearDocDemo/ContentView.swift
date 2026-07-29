//
//  ContentView.swift
//  ClearDocDemo
//
//  Created by Christian Grise on 7/26/26.
//

import SwiftUI
import ClearDoc
import FoundationModels

struct ContentView: View {
    @State private var analyzer = ClearDocAnalyzer()
    @State private var inputText: String = ""
    @State private var summary: ClearDocSummary?
    @State private var isAnalyzing: Bool = false
    @State private var errorMessage: String?
    @State private var availability: ClearDocAvailability = .available
    @State private var showingSamplePicker: Bool = false
    
    var body: some View {
        NavigationStack {
            Group {
                if case .available = availability {
                    availableView
                } else if case .unavailable(let reason) = availability {
                    unavailableView(reason: reason)
                }
            }
            .navigationTitle("ClearDoc")
            .task {
                availability = ClearDocAvailability.current()
            }
            .alert("Error", isPresented: .constant(errorMessage != nil), presenting: errorMessage) { _ in
                Button("OK") { errorMessage = nil }
            } message: { message in
                Text(message)
            }
        }
    }
    
    @ViewBuilder
    private var availableView: some View {
        VStack(spacing: 0) {
            // Input Section
            VStack(alignment: .leading, spacing: 8) {
                Text("Document Text")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                TextEditor(text: $inputText)
                    .frame(minHeight: 150)
                    .padding(8)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay {
                        if inputText.isEmpty {
                            VStack {
                                HStack {
                                    Text("Enter or paste document text here...")
                                        .foregroundStyle(.tertiary)
                                        .padding()
                                    Spacer()
                                }
                                Spacer()
                            }
                            .allowsHitTesting(false)
                        }
                    }
            }
            .padding()
            .background(Color(uiColor: .systemGroupedBackground))
            
            // Action Buttons
            VStack {
                HStack(spacing: 12) {
                    Button {
                        showingSamplePicker = true
                    } label: {
                        Label("Sample Text", systemImage: "doc.text")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(isAnalyzing)
                    
                    Button {
                        analyzeDocument()
                    } label: {
                        if isAnalyzing {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Label("Analyze", systemImage: "sparkles")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(inputText.isEmpty || isAnalyzing)
                }
                Button {
                    resetSession()
                    inputText = ""
                    summary = nil
                    isAnalyzing = false
                } label: {
                    Label("Reset", systemImage: "arrow.counterclockwise")
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .background(Color(uiColor: .systemGroupedBackground))
            
            Divider()
            
            // Results Section
            if let summary {
                summaryView(summary)
            } else {
                emptyResultsView
            }
        }
        .confirmationDialog("Sample Documents", isPresented: $showingSamplePicker) {
            ForEach(SampleText.allCases) { sample in
                Button(sample.label) {
                    inputText = sample.text
                }
            }
            Button("Cancel", role: .cancel) { }
        }
    }
    
    @ViewBuilder
    private func summaryView(_ summary: ClearDocSummary) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Document Category
                HStack {
                    Image(systemName: categoryIcon(for: summary.category))
                        .foregroundStyle(.secondary)
                    Text(summary.category.rawValue)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top)
                
                // Title
                VStack(alignment: .leading, spacing: 4) {
                    Text("Title")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                    Text(summary.title)
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                .padding(.horizontal)
                
                Divider()
                    .padding(.horizontal)
                
                // Plain Language Summary
                VStack(alignment: .leading, spacing: 8) {
                    Label("Summary", systemImage: "text.alignleft")
                        .font(.headline)
                    Text(summary.plainLanguageSummary)
                        .font(.body)
                }
                .padding(.horizontal)
                
                Divider()
                    .padding(.horizontal)
                
                // Key Points
                if !summary.keyPoints.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Key Points", systemImage: "list.bullet")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(Array(summary.keyPoints.enumerated()), id: \.offset) { index, point in
                                HStack(alignment: .top, spacing: 12) {
                                    Text("\(index + 1)")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.white)
                                        .frame(width: 24, height: 24)
                                        .background(Circle().fill(Color.accentColor))
                                    
                                    Text(point)
                                        .font(.body)
                                        .fixedSize(horizontal: false, vertical: true)
                                    
                                    Spacer()
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    Divider()
                        .padding(.horizontal)
                }
                
                // Flagged Terms
                if !summary.flaggedTerms.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Flagged Terms", systemImage: "exclamationmark.triangle.fill")
                            .font(.headline)
                            .foregroundStyle(.orange)
                        
                        FlowLayout(spacing: 8) {
                            ForEach(summary.flaggedTerms, id: \.self) { term in
                                Text(term)
                                    .font(.subheadline)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.orange.opacity(0.15))
                                    .foregroundStyle(.orange)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                Spacer(minLength: 20)
            }
        }
        .background(Color(uiColor: .systemGroupedBackground))
    }
    
    @ViewBuilder
    private var emptyResultsView: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundStyle(.tertiary)
            
            Text("No Analysis Yet")
                .font(.title3)
                .fontWeight(.medium)
            
            Text("Enter document text and tap Analyze to see results")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemGroupedBackground))
    }
    
    @ViewBuilder
    private func unavailableView(reason: String) -> some View {
        ContentUnavailableView {
            Label("Feature Unavailable", systemImage: "exclamationmark.triangle")
        } description: {
            Text(reason)
        }
    }
    
    // MARK: - Actions
    
    private func analyzeDocument() {
        isAnalyzing = true
        errorMessage = nil
        summary = nil
        
        Task {
            do {
                summary = try await analyzer.analyze(inputText)
            } catch let error as LanguageModelSession.GenerationError {
                print("GENERATION ERROR CASE: \(error)")
                errorMessage = error.localizedDescription
            } catch {
                errorMessage = error.localizedDescription
            }
            isAnalyzing = false
        }
    }
    
    private func resetSession() {
        Task {
            await analyzer.reset()
        }
    }
    
    // MARK: - Helpers
    
    private func categoryIcon(for category: ClearDocCategory) -> String {
        switch category {
            case .medical:
                return "cross.case"
            case .personalHealthNote: 
                return "stethoscope"
            case .general:
                return "doc"
            @unknown default:
                return "doc"
        }
    }
}

// MARK: - Flow Layout for Tags

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.replacingUnspecifiedDimensions().width, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if currentX + size.width > maxWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }
                
                positions.append(CGPoint(x: currentX, y: currentY))
                lineHeight = max(lineHeight, size.height)
                currentX += size.width + spacing
            }
            
            self.size = CGSize(width: maxWidth, height: currentY + lineHeight)
        }
    }
}

#Preview {
    ContentView()
}
