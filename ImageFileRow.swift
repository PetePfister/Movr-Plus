import SwiftUI

struct ImageFileRow: View {
    // Use a direct reference to the file in viewModel.imageFiles
    let fileId: UUID
    @ObservedObject var viewModel: MovrPlusViewModel
    
    // Computed properties to get the current file - FIXED to handle nil safely
    private var file: ImageFile? {
        viewModel.imageFiles.first(where: { $0.id == fileId })
    }
    
    // Create state variables that bind to the live data
    private var description: Binding<String> {
        Binding(
            get: { self.file?.description ?? "" },
            set: { newValue in
                guard let file = self.file else { return }
                self.viewModel.updateProductInfo(
                    id: self.fileId,
                    description: newValue,
                    requestID: file.requestID,
                    company: file.company,
                    sequence: file.sequence,
                    isRetouched: false // Always set to false since toggle is removed
                )
            }
        )
    }
    
    private var requestID: Binding<String> {
        Binding(
            get: { self.file?.requestID ?? "" },
            set: { newValue in
                guard let file = self.file else { return }
                self.viewModel.updateProductInfo(
                    id: self.fileId,
                    description: file.description,
                    requestID: newValue,
                    company: file.company,
                    sequence: file.sequence,
                    isRetouched: false
                )
            }
        )
    }
    
    private var sequence: Binding<String> {
        Binding(
            get: { self.file?.sequence ?? "" },
            set: { newValue in
                guard let file = self.file else { return }
                self.viewModel.updateProductInfo(
                    id: self.fileId,
                    description: file.description,
                    requestID: file.requestID,
                    company: file.company,
                    sequence: newValue,
                    isRetouched: false
                )
            }
        )
    }
    
    private var company: Binding<Retailer> {
        Binding(
            get: { self.file?.company ?? .qvc },
            set: { newValue in
                guard let file = self.file else { return }
                self.viewModel.updateProductInfo(
                    id: self.fileId,
                    description: file.description,
                    requestID: file.requestID,
                    company: newValue,
                    sequence: file.sequence,
                    isRetouched: false
                )
            }
        )
    }
    
    private var imageType: Binding<ImageType> {
        Binding(
            get: { self.file?.imageType ?? .lifestyle },
            set: { newValue in
                self.viewModel.updateImageType(id: self.fileId, type: newValue)
            }
        )
    }
    
    private var isVerified: Binding<Bool> {
        Binding(
            get: { self.file?.isVerified ?? false },
            set: { newValue in
                self.viewModel.verifyFile(id: self.fileId, isVerified: newValue)
            }
        )
    }
    
    // State for thumbnail loading
    @State private var isLoadingThumbnail: Bool = false
    @State private var thumbnailImage: NSImage?
    
    var body: some View {
        // Guard against the file being nil - this prevents the crash
        if let currentFile = file {
            VStack(spacing: 8) {
                HStack(spacing: 12) {
                    // Thumbnail without colored border
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.gray.opacity(0.1))
                            .frame(width: 80, height: 80)
                        
                        if let thumbnail = thumbnailImage ?? currentFile.thumbnail {
                            Image(nsImage: thumbnail)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 74, height: 74)
                                .cornerRadius(4)
                        } else if isLoadingThumbnail {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "photo")
                                .font(.system(size: 30))
                                .foregroundColor(.gray)
                        }
                    }
                    .onAppear {
                        loadThumbnail()
                    }
                    
                    // File details
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(currentFile.originalFilename)
                                .font(.headline)
                                .lineLimit(1)
                                .truncationMode(.middle)
                            
                            Spacer()
                            
                            // Company badge with improved color
                            Text(currentFile.company.rawValue)
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .foregroundColor(Color.white)
                                .background(currentFile.company.color)
                                .cornerRadius(12)
                        }
                        
                        // Image Type Selector with blue for all types
                        HStack {
                            Text("Image Type:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            // Custom segmented control with blue for all types
                            HStack(spacing: 0) {
                                ForEach(ImageType.allCases) { type in
                                    Button {
                                        imageType.wrappedValue = type
                                    } label: {
                                        VStack(spacing: 2) {
                                            Text(type.rawValue)
                                                .fontWeight(currentFile.imageType == type ? .medium : .regular)
                                        }
                                        .frame(minWidth: 80)
                                        .padding(.vertical, 6)
                                        .background(currentFile.imageType == type ? Color.blue : Color.gray.opacity(0.1))
                                        .foregroundColor(currentFile.imageType == type ? .white : .primary)
                                    }
                                    .buttonStyle(.plain)
                                    .id("\(fileId)-\(type)-\(type == currentFile.imageType)")
                                }
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                        }
                        
                        // REORDERED INPUT FIELDS: Company, Request ID, Description, Sequence
                        HStack(spacing: 16) {
                            // 1. Company picker with colored buttons
                            VStack(alignment: .leading) {
                                Text("Company:")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                // Custom company picker with color
                                HStack(spacing: 0) {
                                    ForEach(Retailer.allCases) { companyOption in
                                        Button {
                                            company.wrappedValue = companyOption
                                        } label: {
                                            Text(companyOption.rawValue)
                                                .fontWeight(currentFile.company == companyOption ? .medium : .regular)
                                                .frame(minWidth: 60)
                                                .padding(.vertical, 5)
                                                .background(currentFile.company == companyOption ? companyOption.color : Color.gray.opacity(0.1))
                                                .foregroundColor(currentFile.company == companyOption ? .white : .primary)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                            }
                            
                            // 2. Request ID (MO/PH Number)
                            VStack(alignment: .leading) {
                                Text("Request ID (\(currentFile.company == .hsn ? "PH" : "MO") #):")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                HStack {
                                    TextField(currentFile.company == .hsn ? "PH#" : "MO#", text: requestID)
                                        .frame(width: 90)
                                        .textFieldStyle(.roundedBorder)
                                    
                                    if currentFile.requestID.isEmpty {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundColor(.orange)
                                            .help("No Request ID detected. Please enter manually.")
                                    } else {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                    }
                                }
                            }
                            
                            // 3. Description (Item Number)
                            VStack(alignment: .leading) {
                                Text("Description (Item #):")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                HStack {
                                    TextField("Item #", text: description)
                                        .frame(width: 90)
                                        .textFieldStyle(.roundedBorder)
                                    
                                    if currentFile.description.isEmpty {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundColor(.orange)
                                            .help("No item number detected. Please enter manually.")
                                    } else {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                    }
                                }
                            }
                            
                            // 4. Sequence number (if lifestyle image)
                            if currentFile.imageType == .lifestyle {
                                VStack(alignment: .leading) {
                                    Text("Sequence #:")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    HStack {
                                        TextField("Seq", text: sequence)
                                            .frame(width: 60)
                                            .textFieldStyle(.roundedBorder)
                                        
                                        if currentFile.sequence.isEmpty {
                                            Image(systemName: "exclamationmark.triangle.fill")
                                                .foregroundColor(.orange)
                                                .help("No sequence number detected. Default will be used.")
                                        } else {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.green)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Verification toggle - unchanged
                    Toggle("Verified", isOn: isVerified)
                        .toggleStyle(.switch)
                        .disabled(currentFile.newFilename.isEmpty)
                }
                
                // Preview of naming structure with normal color
                VStack(alignment: .leading, spacing: 4) {
                    Text("Naming Pattern:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    switch currentFile.imageType {
                    case .lifestyle:
                        Text("IMG_[Company]_PH_LS_[Request ID]_[Description]_[Sequence#]")
                            .font(.caption)
                            .foregroundColor(.primary) // Using primary color instead of type color
                            .padding(.bottom, 2)
                    case .product:
                        Text("IMG_[Company]_PH_PR_[Request ID]_[Description]")
                            .font(.caption)
                            .foregroundColor(.primary) // Using primary color instead of type color
                            .padding(.bottom, 2)
                    case .headshot:
                        Text("IMG_[Company]_PH_HS_[Request ID]_[Description]")
                            .font(.caption)
                            .foregroundColor(.primary) // Using primary color instead of type color
                            .padding(.bottom, 2)
                    case .pdLifestyleLite:
                        Text("IMG_PH_PD_[Business]_[YYMM]_[Category]_[Filename_R]")
                            .font(.caption)
                            .foregroundColor(.primary)
                            .padding(.bottom, 2)
                    case .foodShoot:
                        Text("IMG_PH_PD_[Business]_[YYMM]_QC_[Filename_R]")
                            .font(.caption)
                            .foregroundColor(.primary)
                            .padding(.bottom, 2)
                    case .standard:
                        Text("Custom flex filename pattern")
                            .font(.caption)
                            .foregroundColor(.primary)
                            .padding(.bottom, 2)
                    @unknown default:
                        Text("Pattern varies by type")
                            .font(.caption)
                            .foregroundColor(.primary)
                            .padding(.bottom, 2)
                    }
                    
                    // New filename preview
                    HStack {
                        Text("New filename:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text(currentFile.newFilename.isEmpty ? "Invalid filename" : currentFile.newFilename)
                            .fontWeight(.medium)
                            .foregroundColor(currentFile.newFilename.isEmpty ? .red : .blue) // Always blue if valid
                        
                        Spacer()
                        
                        Text("Destination: \(currentFile.destinationFolder)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 10)
                .background(Color.gray.opacity(0.07))
                .cornerRadius(4)
                
                // Error message if any
                if let error = currentFile.processingError {
                    Text("Error: \(error)")
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.top, 4)
                }
            }
            // Force view to update when image type changes
            .id("\(fileId)-\(currentFile.imageType)-\(currentFile.company)")
            .contextMenu {
                Button {
                    viewModel.verifyFile(id: fileId, isVerified: true)
                } label: {
                    Label("Verify", systemImage: "checkmark.circle")
                }
                
                Button {
                    viewModel.verifyFile(id: fileId, isVerified: false)
                } label: {
                    Label("Unverify", systemImage: "xmark.circle")
                }
                
                Divider()
                
                Menu("Change Image Type") {
                    ForEach(ImageType.allCases) { type in
                        Button(type.rawValue) {
                            viewModel.updateImageType(id: fileId, type: type)
                        }
                    }
                }
                
                Menu("Change Company") {
                    ForEach(Retailer.allCases) { company in
                        Button(company.rawValue) {
                            if let file = self.file {
                                viewModel.updateProductInfo(
                                    id: fileId,
                                    description: file.description,
                                    requestID: file.requestID,
                                    company: company,
                                    sequence: file.sequence,
                                    isRetouched: false
                                )
                            }
                        }
                    }
                }
                
                Divider()
                
                Button(role: .destructive) {
                    viewModel.removeFile(id: fileId)
                } label: {
                    Label("Remove File", systemImage: "trash")
                }
            }
        } else {
            // Return empty view if file is nil (this should not render, but prevents crashes)
            EmptyView()
        }
    }
    
    private func loadThumbnail() {
        // Safely handle the case where file might be nil
        guard let currentFile = file, thumbnailImage == nil, currentFile.thumbnail == nil, !isLoadingThumbnail else {
            return
        }
        
        // Load it asynchronously
        isLoadingThumbnail = true
        ThumbnailManager.shared.thumbnail(for: currentFile.originalURL) { image in
            DispatchQueue.main.async {
                thumbnailImage = image
                isLoadingThumbnail = false
                
                // Update the file's thumbnail in the viewModel
                self.viewModel.updateThumbnail(id: self.fileId, thumbnail: image)
            }
        }
    }
}
