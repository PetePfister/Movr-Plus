import SwiftUI

struct BatchControlsButton: View {
    @Binding var isExpanded: Bool
    
    var body: some View {
        Button {
            isExpanded.toggle()
        } label: {
            HStack {
                Text(isExpanded ? "Hide Batch Controls" : "Show Batch Controls")
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
            }
            .font(.headline)
            .padding(.vertical, 8)
            .padding(.horizontal, 14)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .padding(.bottom, 6)
    }
}

struct BatchControlPanel: View {
    @EnvironmentObject var viewModel: MovrPlusViewModel
    @State private var batchImageType: ImageType = .lifestyle
    @State private var batchCompany: Retailer = .qvc
    @State private var batchDescription: String = ""
    @State private var batchRequestID: String = ""
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Apply Settings to All Files")
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack(spacing: 20) {
                // Image Type
                VStack(alignment: .leading) {
                    Text("Image Type:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Picker("", selection: $batchImageType) {
                            ForEach(ImageType.allCases) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 120)
                        
                        Button("Apply") {
                            for file in viewModel.imageFiles {
                                viewModel.updateImageType(id: file.id, type: batchImageType)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                }
                
                // Company
                VStack(alignment: .leading) {
                    Text("Company:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Picker("", selection: $batchCompany) {
                            ForEach(Retailer.allCases) { company in
                                Text(company.rawValue).tag(company)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 120)
                        
                        Button("Apply") {
                            for file in viewModel.imageFiles {
                                viewModel.updateProductInfo(
                                    id: file.id,
                                    description: file.description,
                                    requestID: file.requestID,
                                    company: batchCompany,
                                    sequence: file.sequence,
                                    isRetouched: false
                                )
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                }
                
                // Description (Item #)
                VStack(alignment: .leading) {
                    Text("Description (Item #):")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        TextField("Item #", text: $batchDescription)
                            .frame(width: 120)
                            .textFieldStyle(.roundedBorder)
                        
                        Button("Apply") {
                            for file in viewModel.imageFiles {
                                viewModel.updateProductInfo(
                                    id: file.id,
                                    description: batchDescription.isEmpty ? file.description : batchDescription,
                                    requestID: file.requestID,
                                    company: file.company,
                                    sequence: file.sequence,
                                    isRetouched: false
                                )
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        .disabled(batchDescription.isEmpty)
                    }
                }
                
                // Request ID
                VStack(alignment: .leading) {
                    Text("Request ID:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        TextField(batchCompany == .hsn ? "PH#" : "MO#", text: $batchRequestID)
                            .frame(width: 120)
                            .textFieldStyle(.roundedBorder)
                        
                        Button("Apply") {
                            for file in viewModel.imageFiles {
                                viewModel.updateProductInfo(
                                    id: file.id,
                                    description: file.description,
                                    requestID: batchRequestID.isEmpty ? file.requestID : batchRequestID,
                                    company: file.company,
                                    sequence: file.sequence,
                                    isRetouched: false
                                )
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        .disabled(batchRequestID.isEmpty)
                    }
                }
                
                // Verify All toggle
                VStack(alignment: .leading) {
                    Text("Verification:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button {
                        viewModel.toggleVerifyAllFiles()
                    } label: {
                        HStack {
                            Image(systemName: viewModel.areAllFilesVerified() ? "checkmark.square.fill" : "square")
                                .foregroundColor(.blue)
                            Text(viewModel.areAllFilesVerified() ? "Unverify All" : "Verify All")
                                .fontWeight(.medium)
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
        .background(Color(.windowBackgroundColor))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .padding(.bottom, 10)
    }
}
