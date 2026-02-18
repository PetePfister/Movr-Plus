import SwiftUI

struct DropAreaView: View {
    let isTargeted: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "arrow.down.doc")
                .font(.system(size: 40))
                .foregroundColor(isTargeted ? .blue : .gray)
                .scaleEffect(isTargeted ? 1.2 : 1.0)
            
            Text("Drop image files here")
                .font(.headline)
            
            Text("Supported formats include:")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(".jpg, .jpeg, .tif, .tiff, .png, .ai, .svg, .eps, .gif, .r3d, .cr2, .rtn, .bmp, .pct, .arw, .dpx, .psb, .thm, .heic, .ps, .psd, .avif, .tga")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
    }
}