import SwiftUI

struct EdgeExplorer: View {
    var body: some View {
        GeometryReader { proxy in
            let insets = proxy.safeAreaInsets

            ZStack {
                // Background ignores the safe area, so color reaches the edges
                Color.yellow.ignoresSafeArea()

                // Content respects the safe area by default
                VStack {
                    HStack {
                        cornerButton("top-leading")
                        Spacer()
                        cornerButton("top-trailing")
                    }
                    Spacer()
                    HStack {
                        cornerButton("bottom-leading")
                        Spacer()
                        cornerButton("bottom-trailing")
                    }
                }
                .padding()

                // Debug readout of the insets for the current orientation
                Text("T \(Int(insets.top)) B \(Int(insets.bottom)) L \(Int(insets.leading)) R \(Int(insets.trailing))")
                    .font(.caption.monospaced())
                    .padding(6)
                    .background(.black.opacity(0.6), in: .capsule)
                    .foregroundStyle(.white)
            }
        }
    }

    func cornerButton(_ label: String) -> some View {
        Button {
            print("tapped \(label)")
        } label: {
            Image(systemName: "xmark")
                .padding(8)
        }
        .buttonStyle(.glass)
    }
}

#Preview {
    EdgeExplorer()
}
