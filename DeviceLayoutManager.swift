//
//  DeviceLayoutManager.swift
//  PuppyTracking
//
//  Created by Dev Maurya on 05/11/26.
//

///🔴 This class helps us to identify iPhone Duo device current state.

import SwiftUI

enum DeviceLayoutState {
    case compactPortrait
    case compactLandscape
    case expandedPortrait
    case expandedLandscape
}

enum HingeState {
    case unavailable
    case closed
    case partiallyOpen
    case fullyOpen
}

@MainActor
final class DeviceLayoutManager: ObservableObject {

    static let shared = DeviceLayoutManager()

    @Published private(set) var layoutState: DeviceLayoutState = .compactPortrait
    
    @Published private(set) var screenSize: CGSize = .zero
    
    @Published private(set) var hingeAngle: Double?
    @Published private(set) var hingeState: HingeState = .unavailable

    var isLandscape: Bool {
        switch layoutState {
        case .compactLandscape, .expandedLandscape:
            return true
        default:
            return false
        }
    }

    var isExpanded: Bool {
        switch layoutState {
        case .expandedPortrait, .expandedLandscape:
            return true
        default:
            return false
        }
    }
    
    var isExpandedLandscape: Bool {
        layoutState == .expandedLandscape
    }
    
    var isPartiallyOpen: Bool {
        hingeState == .partiallyOpen
    }

    var hingeAngleInDegrees: Double {
        hingeAngle ?? 0
    }

    private init() {}

    func update( size: CGSize, horizontalSizeClass: UserInterfaceSizeClass?, verticalSizeClass: UserInterfaceSizeClass?) {

        screenSize = size

        let landscape = size.width > size.height

        // Regular horizontal size class is used as
        // an expanded-layout heuristic.
        let expanded = horizontalSizeClass == .regular

        if expanded {
            layoutState = landscape ? .expandedLandscape : .expandedPortrait
        } else {
            layoutState = landscape ? .compactLandscape : .compactPortrait
        }
    }
    
    @available(anyAppleOS 27.1, *)
    func updateHinge(_ hinge: DeviceHinge?) {

        guard let hinge else {
            hingeAngle = nil
            hingeState = .unavailable
            return
        }

        hingeAngle = hinge.angle.degrees

        if hinge.status == .closed {
            hingeState = .closed
        } else if hinge.status == .partiallyOpen {
            hingeState = .partiallyOpen
        } else if hinge.status == .fullyOpen {
            hingeState = .fullyOpen
        }
    }
}


struct DeviceLayoutProvider<Content: View>: View {

    @StateObject private var manager = DeviceLayoutManager.shared

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @Environment(\.verticalSizeClass) private var verticalSizeClass

    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {

        GeometryReader { geometry in

            if #available(anyAppleOS 27.1, *) {
                content
                    .environmentObject(manager)
                    .onHingeChange { _, newContext in
                        manager.updateHinge(newContext.hinge)
                    }
                    .onAppear {
                        updateLayout(size: geometry.size)
                    }
                    .onChange(of: geometry.size) { _, newSize in
                        updateLayout(size: newSize)
                    }
                    .onChange(of: horizontalSizeClass) { _, _ in
                        updateLayout(size: geometry.size)
                    }
                    .onChange(of: verticalSizeClass) { _, _ in
                        updateLayout(size: geometry.size)
                    }
            } else {
                content
                    .environmentObject(manager)
                    .onAppear {
                        updateLayout(size: geometry.size)
                    }
                    .onChange(of: geometry.size) { _, newSize in
                        updateLayout(size: newSize)
                    }
                    .onChange(of: horizontalSizeClass) { _, _ in
                        updateLayout(size: geometry.size)
                    }
                    .onChange(of: verticalSizeClass) { _, _ in
                        updateLayout(size: geometry.size)
                    }
            }
        }
    }

    private func updateLayout(size: CGSize) {
        manager.update(
            size: size,
            horizontalSizeClass: horizontalSizeClass,
            verticalSizeClass: verticalSizeClass
        )
    }
}
