//
//  MakeViewsInSafeArea.swift
//  FirstDUO
//
//  Created by Dev Maurya on 16/10/26.
//

import SwiftUI

struct EdgeExplorer: View {

    // Access shared screen information from the environment.
    // ScreenInfo is expected to provide the current orientation.
    @EnvironmentObject var screenInfo: ScreenInfo

    var body: some View {

        // Dynamically choose the layout based on screen orientation.
        // Landscape: arrange items vertically.
        // Portrait: arrange items horizontally.
        //
        // AnyLayout allows switching between layout types without
        // duplicating the views contained inside the layout.
        let layout = screenInfo.isLandscape
            ? AnyLayout(VStackLayout())
            : AnyLayout(HStackLayout())

        NavigationStack {

            // Main content that demonstrates safe-area behavior.
            self.mainView

                // Configure navigation bar items.
                .toolbar {

                    // MARK: - Leading Toolbar Button

                    // Place a wide button at the leading side
                    // of the navigation bar.
                    ToolbarItem(placement: .topBarLeading) {

                        Button {
                            print("leading tapped")
                        } label: {

                            Image(systemName: "xmark")

                                // Increase the tappable area
                                // without changing the icon size.
                                .frame(width: 80, height: 44)

                                // Make the entire frame respond to taps.
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }

                    // Hide the default shared toolbar background
                    // for this toolbar item.
                    .sharedBackgroundVisibility(.hidden)


                    // MARK: - Pinned Trailing Toolbar Items

                    // Display two circular items at the pinned
                    // trailing position of the navigation bar.
                    ToolbarItem(placement: .topBarPinnedTrailing) {

                        // Switch the arrangement according to orientation.
                        // Landscape uses VStack; portrait uses HStack.
                        layout {

                            // Circle A
                            Circle()
                                .stroke(.red, lineWidth: 1)
                                .overlay(alignment: .center) {
                                    Text("A")
                                        .foregroundStyle(.red)
                                }
                                .onTapGesture {
                                    print("Circle A")
                                }

                            // Circle B
                            Circle()
                                .stroke(.black, lineWidth: 1)
                                .overlay(alignment: .center) {
                                    Text("B")
                                        .foregroundStyle(.black)
                                }
                                .onTapGesture {
                                    print("Circle B")
                                }
                        }
                    }

                    // Hide the shared background behind the circles.
                    .sharedBackgroundVisibility(.hidden)

                    // Prefer a vertical arrangement when the toolbar
                    // supports vertical placement.
                    .axisBehavior(.verticalPreferred)


                    // MARK: - Trailing Toolbar Buttons

                    // Group related actions on the trailing side.
                    ToolbarItemGroup(placement: .topBarTrailing) {

                        // Share action
                        Button {
                            print("share tapped")
                        } label: {

                            Image(systemName: "square.and.arrow.up")

                                // Provide a wider interaction area.
                                .frame(width: 80, height: 44)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)


                        // More options action
                        Button {
                            print("more tapped")
                        } label: {

                            Image(systemName: "ellipsis")

                                // Provide a wider interaction area.
                                .frame(width: 80, height: 44)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }

                    // Hide the default shared background.
                    .sharedBackgroundVisibility(.hidden)

                    // Allow vertical placement when supported.
                    .axisBehavior(.verticalPreferred)
                }


// MARK: - Alternative Toolbar Implementation

// The following commented-out implementation is preserved as an
// alternative if you want a conventional navigation toolbar.
//
// .toolbar {
//     // Leading side of the navigation bar
//     ToolbarItem(placement: .topBarLeading) {
//         Button {
//             print("leading tapped")
//         } label: {
//             Image(systemName: "xmark")
//         }
//     }
//
//     // Trailing side of the navigation bar
//     ToolbarItemGroup(placement: .topBarTrailing) {
//         Button {
//             print("share tapped")
//         } label: {
//             Image(systemName: "square.and.arrow.up")
//         }
//
//         Button {
//             print("more tapped")
//         } label: {
//             Image(systemName: "ellipsis")
//         }
//     }
//
//     // Bottom toolbar with actions at opposite ends
//     ToolbarItemGroup(placement: .bottomBar) {
//         Button("Like") { }
//
//         Spacer()
//
//         Button("Comment") { }
//     }
// }
        }
    }


    // MARK: - Main View

    var mainView: some View {

        // GeometryReader provides the available size and safe-area
        // insets for the view in its current layout.
        GeometryReader { proxy in

            // Read the safe-area insets for the current orientation.
            // These values can change when the device rotates.
            let insets = proxy.safeAreaInsets

            ZStack {

                // MARK: Background

                // Extend the yellow background into the safe areas.
                // This allows the color to reach the screen edges,
                // including areas behind system interface elements.
                Color.yellow
                    .ignoresSafeArea()


                // MARK: Corner Buttons

                // Arrange buttons near the four corners of the
                // available content area while respecting safe areas.
                VStack {

                    // Top row: leading and trailing buttons.
                    HStack {

                        // Top-leading corner button.
                        cornerButton("top-leading")

                        // Push the next button to the opposite side.
                        Spacer()

                        // Top-trailing corner button.
                        cornerButton("top-trailing")
                    }

                    // Push the next row toward the bottom.
                    Spacer()

                    // Bottom row: leading and trailing buttons.
                    HStack {

                        // Bottom-leading corner button.
                        cornerButton("bottom-leading")

                        // Separate the buttons horizontally.
                        Spacer()

                        // Bottom-trailing corner button.
                        cornerButton("bottom-trailing")
                    }
                }

                // Keep the corner buttons away from the edges
                // of the available content area.
                .padding()


                // MARK: Safe-Area Debug Information

                // Display the current safe-area inset values.
                // Int() converts the floating-point measurements
                // into readable whole numbers.
                Text(
                    "T \(Int(insets.top)) " +
                    "B \(Int(insets.bottom)) " +
                    "L \(Int(insets.leading)) " +
                    "R \(Int(insets.trailing))"
                )
                .font(.caption.monospaced())

                // Add space around the debug text.
                .padding(6)

                // Use a translucent capsule as the label background.
                .background(
                    .black.opacity(0.6),
                    in: .capsule
                )

                // Keep the text readable on the yellow background.
                .foregroundStyle(.white)
            }
        }
    }


    // MARK: - Reusable Corner Button

    // Creates a reusable button with a glass visual style.
    // The label identifies which corner button was tapped.
    func cornerButton(_ label: String) -> some View {

        Button {

            // Print the button identifier for debugging.
            print("tapped \(label)")

        } label: {

            // Use an X icon to identify the button.
            Image(systemName: "xmark")

                // Add internal padding around the icon.
                .padding(8)
        }

        // Apply SwiftUI's glass button style.
        .buttonStyle(.glass)
    }
}


// MARK: - Preview

#Preview {

    // Display EdgeExplorer in the preview canvas.
    //
    // If ScreenInfo is not provided elsewhere through the preview
    // environment, inject a ScreenInfo instance here.
    EdgeExplorer()
}
