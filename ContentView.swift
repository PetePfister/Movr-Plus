import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject var viewModel: MovrPlusViewModel
    @State private var isTargeted = false
    @State private var showingLogViewer = false
    @State private var showingImportDialog = false
    @State private var showingBatchControls = true
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var toastStyle: ToastStyle = .info
    @State private var selectedFiles: Set<UUID> = []
    @State private var showingProgress = false
    @State private var currentProgress: Double = 0
    
    enum ToastStyle {
        case success, error, info, warning
        
        var color: Color {
            switch self {
            case .success: return .green
            case .error: return .red
            case .warning: return .orange
            case .info: return .blue
            }
        }
        
        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .error: return "exclamationmark.triangle.fill"
            case .warning: return "exclamationmark.circle.fill"
            case .info: return "info.circle.fill"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with enhanced info
            HeaderView(viewModel: viewModel)
            
            // Quick stats bar
            if !viewModel.imageFiles.isEmpty {
                QuickStatsBar(viewModel: viewModel)
            }
            
            // Batch Type Selector (before dropping files)
            if viewModel.imageFiles.isEmpty {
                BatchTypeSelector(viewModel: viewModel)
            }
            
            // Batch Controls (when files exist)
            if !viewModel.imageFiles.isEmpty {
                HStack {
                    Spacer()
                    BatchControlsButton(isExpanded: $showingBatchControls)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.bottom, 6)
                
                if showingBatchControls {
                    BatchControlPanel()
                        .transition(AnyTransition.opacity.combined(with: .move(edge: .top)))
                }
            }
            
            // Main content area with enhanced drop zone
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray.opacity(isTargeted ? 0.3 : 0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isTargeted ? Color.blue : Color.gray, lineWidth: 2)
                    )
                
                if viewModel.imageFiles.isEmpty {
                    // Enhanced drop area
                    VStack(spacing: 20) {
                        Image(systemName: "arrow.down.doc.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 64, height: 64)
                            .foregroundColor(isTargeted ? .blue : .gray)
                            .scaleEffect(isTargeted ? 1.1 : 1.0)
                            .animation(.spring(), value: isTargeted)
                        
                        VStack(spacing: 8) {
                            Text("Drop files here or click to import")
                                .font(.title3)
                                .foregroundColor(isTargeted ? .primary : .secondary)
                            
                            Text("Supports: JPG, PNG, TIFF, HEIC, AI, PSD, and more")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        // Quick action buttons
                        HStack(spacing: 12) {
                            Button("Browse Files") {
                                showingImportDialog = true
                            }
                            .buttonStyle(.borderedProminent)
                            
                            Button("Load Recent") {
                                viewModel.loadSavedFiles()
                                if !viewModel.imageFiles.isEmpty {
                                    showToast(message: "Loaded \(viewModel.imageFiles.count) files from previous session", style: .success)
                                }
                            }
                            .buttonStyle(.bordered)
                            .disabled(RecentFilesManager.shared.recentDestinationPaths.isEmpty)
                        }
                    }
                    .padding()
                    .onTapGesture {
                        showingImportDialog = true
                    }
                } else {
                    ImageFileListView(viewModel: viewModel)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
            .onDrop(of: [UTType.fileURL], isTargeted: $isTargeted) { providers in
                viewModel.handleFileDrop(providers: providers)
                return true
            }
            
            // Enhanced status bar
            if !viewModel.processingMessage.isEmpty || viewModel.isProcessing {
                ProcessingStatusBar(viewModel: viewModel)
            }
            
            // Enhanced action buttons
            ActionButtonsBar(viewModel: viewModel,
                           showingLogViewer: $showingLogViewer,
                           showingBatchControls: $showingBatchControls,
                           onShowToast: showToast)
        }
        .padding()
        .sheet(isPresented: $showingLogViewer) {
            LogViewer()
        }
        .fileImporter(
            isPresented: $showingImportDialog,
            allowedContentTypes: [.image],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                viewModel.importFiles(from: urls)
                showToast(message: "Imported \(urls.count) files", style: .success)
            case .failure(let error):
                showToast(message: "Error importing files: \(error.localizedDescription)", style: .error)
            }
        }
        .alert("Error", isPresented: $viewModel.showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
        .sheet(isPresented: $viewModel.showBusinessSelector) {
            BusinessSelectorDialog(
                isPresented: $viewModel.showBusinessSelector,
                selectedBusiness: $viewModel.selectedWorkflowBusiness,
                onConfirm: {
                    // Continue workflow based on batch type
                    if viewModel.selectedBatchType == .pdLifestyleLite {
                        viewModel.continuePDLifestyleLiteWorkflow()
                    } else if viewModel.selectedBatchType == .foodShoot {
                        viewModel.continueFoodShootWorkflow()
                    }
                }
            )
        }
        .sheet(isPresented: $viewModel.showCategoryInput) {
            CategoryInputDialog(
                isPresented: $viewModel.showCategoryInput,
                category: $viewModel.workflowCategory,
                onConfirm: {
                    viewModel.continuePDLifestyleLiteWithCategory()
                }
            )
        }
        .sheet(isPresented: $viewModel.showFlexFilenameInput) {
            FlexFilenameInputDialog(
                isPresented: $viewModel.showFlexFilenameInput,
                flexFilename: $viewModel.workflowFlexFilename,
                onConfirm: {
                    viewModel.continueStandardWorkflowWithFlexName()
                }
            )
        }
        .sheet(isPresented: $viewModel.showRetouchedVerification) {
            RetouchedVerificationDialog(
                isPresented: $viewModel.showRetouchedVerification,
                onYes: {
                    viewModel.continueStandardWorkflowWithR()
                },
                onNo: {
                    viewModel.abortStandardWorkflow()
                }
            )
        }
        .sheet(isPresented: $viewModel.showManualArchiveVerification) {
            ManualArchiveVerificationDialog(
                isPresented: $viewModel.showManualArchiveVerification,
                message: viewModel.manualArchiveMessage,
                onVerified: {
                    viewModel.completeManualArchive()
                }
            )
        }
        .animation(.easeInOut(duration: 0.2), value: showingBatchControls)
        .overlay(
            // Enhanced toast with auto-dismiss
            Group {
                if showToast {
                    VStack {
                        Spacer()
                        ToastView(message: toastMessage, style: toastStyle) {
                            withAnimation {
                                showToast = false
                            }
                        }
                    }
                    .transition(.move(edge: .bottom))
                }
            }
            .animation(.spring(), value: showToast)
        )
        .onAppear {
            // Auto-save state
            loadAppState()
        }
        .onDisappear {
            saveAppState()
        }
    }
    
    // MARK: - Helper Methods
    
    func showToast(message: String, style: ToastStyle) {
        self.toastMessage = message
        self.toastStyle = style
        withAnimation {
            self.showToast = true
        }
        
        // Auto-hide with different durations based on type
        let duration: TimeInterval = style == .error ? 6.0 : 4.0
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            withAnimation {
                if self.toastMessage == message {
                    self.showToast = false
                }
            }
        }
    }
    
    private func loadAppState() {
        // Restore UI state
        if let showControls = UserDefaults.standard.object(forKey: "showingBatchControls") as? Bool {
            showingBatchControls = showControls
        }
    }
    
    private func saveAppState() {
        UserDefaults.standard.set(showingBatchControls, forKey: "showingBatchControls")
    }
}

// MARK: - Supporting Views

struct QuickStatsBar: View {
    @ObservedObject var viewModel: MovrPlusViewModel
    
    private var stats: (verified: Int, total: Int, types: [ImageType: Int]) {
        let verified = viewModel.imageFiles.filter { $0.isVerified }.count
        let total = viewModel.imageFiles.count
        var types: [ImageType: Int] = [:]
        
        for file in viewModel.imageFiles {
            types[file.imageType, default: 0] += 1
        }
        
        return (verified, total, types)
    }
    
    var body: some View {
        let currentStats = stats
        
        HStack {
            // File count
            HStack(spacing: 4) {
                Image(systemName: "doc.text")
                    .foregroundColor(.blue)
                Text("\(currentStats.total) files")
                    .fontWeight(.medium)
            }
            
            Spacer()
            
            // Verification status
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(currentStats.verified == currentStats.total ? .green : .orange)
                Text("\(currentStats.verified)/\(currentStats.total) verified")
                    .font(.caption)
            }
            
            Spacer()
            
            // Type breakdown
            HStack(spacing: 8) {
                ForEach(ImageType.allCases) { type in
                    if let count = currentStats.types[type], count > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: type.icon)
                                .font(.caption)
                            Text("\(count)")
                                .font(.caption)
                        }
                        .foregroundColor(type.color)
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
        .background(Color(.controlBackgroundColor))
        .cornerRadius(6)
        .padding(.horizontal)
    }
}

struct ProcessingStatusBar: View {
    @ObservedObject var viewModel: MovrPlusViewModel
    
    var body: some View {
        VStack(spacing: 8) {
            if viewModel.isProcessing {
                ProgressView(value: viewModel.processingProgress)
                    .progressViewStyle(LinearProgressViewStyle())
                    .padding(.horizontal)
                
                // Show speed and ETA if available
                if viewModel.processingSpeed > 0 {
                    HStack {
                        Text("Speed: \(String(format: "%.1f", viewModel.processingSpeed)) files/sec")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        if viewModel.estimatedTimeRemaining > 0 {
                            Text("ETA: \(viewModel.formatTimeRemaining(viewModel.estimatedTimeRemaining))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            Text(viewModel.processingMessage)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(viewModel.isProcessing ? Color.blue.opacity(0.1) : Color.green.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal)
        }
    }
}

// Replace the ActionButtonsBar struct with this version (Auto-Fill button removed):

struct ActionButtonsBar: View {
    @ObservedObject var viewModel: MovrPlusViewModel
    @Binding var showingLogViewer: Bool
    @Binding var showingBatchControls: Bool
    let onShowToast: (String, ContentView.ToastStyle) -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Clear button
            Button("Clear All") {
                viewModel.clearFiles()
                showingBatchControls = true
            }
            .buttonStyle(.bordered)
            .disabled(viewModel.imageFiles.isEmpty || viewModel.isProcessing)
            
            Spacer()
            
            // View log button
            Button("View Log") {
                showingLogViewer = true
            }
            .buttonStyle(.bordered)
            .disabled(ProcessingLog.shared.isEmpty)
            
            // Process button with enhanced progress
            Button {
                viewModel.processFiles()
            } label: {
                HStack {
                    if viewModel.isProcessing {
                        ProgressView()
                            .scaleEffect(0.7)
                            .padding(.trailing, 5)
                        Text("Processing...")
                    } else {
                        Image(systemName: "arrow.right.circle.fill")
                        Text("Process Files (\(viewModel.imageFiles.count))")
                    }
                }
                .frame(minWidth: 180)
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.imageFiles.isEmpty || viewModel.isProcessing || viewModel.baseDestinationPath.isEmpty)
        }
        .padding()
    }
}

struct ToastView: View {
    let message: String
    let style: ContentView.ToastStyle
    let onDismiss: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: style.icon)
                .foregroundColor(style.color)
            Text(message)
                .foregroundColor(.primary)
            Spacer()
            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .foregroundColor(.gray)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.windowBackgroundColor))
                .shadow(radius: 5)
        )
        .padding()
    }
}
