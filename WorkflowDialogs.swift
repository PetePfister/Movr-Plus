import SwiftUI

// MARK: - Workflow Selection Dialog
struct WorkflowSelectionDialog: View {
    @Binding var isPresented: Bool
    let onPDLifestyleLite: () -> Void
    let onFoodShoot: () -> Void
    let onNeither: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Text("What type of images are these?")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Select the workflow for this batch:")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack(spacing: 20) {
                Button {
                    isPresented = false
                    onPDLifestyleLite()
                } label: {
                    VStack(spacing: 12) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 36))
                            .foregroundColor(.blue)
                        Text("PD Lifestyle Lite")
                            .font(.headline)
                            .multilineTextAlignment(.center)
                    }
                    .frame(width: 150, height: 120)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue, lineWidth: 2)
                    )
                }
                .buttonStyle(.plain)
                
                Button {
                    isPresented = false
                    onFoodShoot()
                } label: {
                    VStack(spacing: 12) {
                        Image(systemName: "fork.knife")
                            .font(.system(size: 36))
                            .foregroundColor(.green)
                        Text("Food Shoot")
                            .font(.headline)
                            .multilineTextAlignment(.center)
                    }
                    .frame(width: 150, height: 120)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.green, lineWidth: 2)
                    )
                }
                .buttonStyle(.plain)
                
                Button {
                    isPresented = false
                    onNeither()
                } label: {
                    VStack(spacing: 12) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 36))
                            .foregroundColor(.orange)
                        Text("Neither")
                            .font(.headline)
                            .multilineTextAlignment(.center)
                    }
                    .frame(width: 150, height: 120)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.orange, lineWidth: 2)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(32)
        .frame(width: 550)
    }
}

// MARK: - Business Selector Dialog (QVC/HSN)
struct BusinessSelectorDialog: View {
    @Binding var isPresented: Bool
    @Binding var selectedBusiness: Retailer
    let onConfirm: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Select Business")
                .font(.headline)
            
            Text("Which business are these images for?")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack(spacing: 20) {
                Button {
                    selectedBusiness = .qvc
                    isPresented = false
                    onConfirm()
                } label: {
                    VStack(spacing: 8) {
                        Text("QVC")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    .frame(width: 120, height: 80)
                    .background(Retailer.qvc.backgroundColor)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Retailer.qvc.color, lineWidth: 2)
                    )
                }
                .buttonStyle(.plain)
                
                Button {
                    selectedBusiness = .hsn
                    isPresented = false
                    onConfirm()
                } label: {
                    VStack(spacing: 8) {
                        Text("HSN")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    .frame(width: 120, height: 80)
                    .background(Retailer.hsn.backgroundColor)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Retailer.hsn.color, lineWidth: 2)
                    )
                }
                .buttonStyle(.plain)
            }
            
            Button("Cancel") {
                isPresented = false
            }
            .keyboardShortcut(.cancelAction)
        }
        .padding(24)
        .frame(width: 350)
    }
}

// MARK: - Category Input Dialog
struct CategoryInputDialog: View {
    @Binding var isPresented: Bool
    @Binding var category: String
    let onConfirm: () -> Void
    
    @State private var inputText: String = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Enter Category")
                .font(.headline)
            
            Text("The item number (product ID) doesn't start with H, M, or K.\nPlease enter the category code:")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            TextField("Category (e.g., HO, QC)", text: $inputText)
                .textFieldStyle(.roundedBorder)
                .frame(width: 200)
            
            HStack(spacing: 12) {
                Button("Cancel") {
                    isPresented = false
                }
                .keyboardShortcut(.cancelAction)
                
                Button("OK") {
                    category = inputText.uppercased()
                    isPresented = false
                    onConfirm()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(inputText.isEmpty)
            }
        }
        .padding(24)
        .frame(width: 400)
    }
}

// MARK: - Flex Filename Input Dialog
struct FlexFilenameInputDialog: View {
    @Binding var isPresented: Bool
    @Binding var flexFilename: String
    let onConfirm: () -> Void
    
    @State private var inputText: String = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Enter Flex Filename")
                .font(.headline)
            
            Text("Please paste the flex file name from Airtable:")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            TextField("Flex filename", text: $inputText)
                .textFieldStyle(.roundedBorder)
                .frame(width: 300)
            
            HStack(spacing: 12) {
                Button("Cancel") {
                    isPresented = false
                }
                .keyboardShortcut(.cancelAction)
                
                Button("OK") {
                    flexFilename = inputText
                    isPresented = false
                    onConfirm()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(inputText.isEmpty)
            }
        }
        .padding(24)
        .frame(width: 400)
    }
}

// MARK: - Retouched Verification Dialog
struct RetouchedVerificationDialog: View {
    @Binding var isPresented: Bool
    let onYes: () -> Void
    let onNo: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            Text("Are these retouched images?")
                .font(.headline)
            
            Text("Files don't have _R suffix. Please confirm if they are retouched.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 12) {
                Button("No - Abort") {
                    isPresented = false
                    onNo()
                }
                .keyboardShortcut(.cancelAction)
                
                Button("Yes - Add _R") {
                    isPresented = false
                    onYes()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 400)
    }
}

// MARK: - Manual Archive Verification Dialog
struct ManualArchiveVerificationDialog: View {
    @Binding var isPresented: Bool
    let message: String
    let onVerified: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "folder.badge.questionmark")
                .font(.system(size: 48))
                .foregroundColor(.blue)
            
            Text("Manual Archive Required")
                .font(.headline)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Text("Please archive the files manually, then click Complete to continue.")
                .font(.caption)
                .foregroundColor(.orange)
                .multilineTextAlignment(.center)
            
            Button("Complete") {
                isPresented = false
                onVerified()
            }
            .keyboardShortcut(.defaultAction)
        }
        .padding(24)
        .frame(width: 450)
    }
}

// MARK: - Progress Dialog
struct ProgressDialog: View {
    let message: String
    @Binding var progress: Double
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView(value: progress)
                .progressViewStyle(.linear)
                .frame(width: 300)
            
            Text(message)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(24)
        .frame(width: 400)
    }
}
