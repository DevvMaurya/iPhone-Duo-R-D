//
//  ExposeReservedRegion.swift
//  FirstDUO
//
//  Created by Dev Maurya on 15/10/26.
//
import SwiftUI

enum Side: CaseIterable, Hashable {
    case top, bottom, leading, trailing
}

/// Free space around the screen: safe area plus hardware reserved regions.
struct EdgeLayout: Equatable {
    var safeArea: EdgeInsets = EdgeInsets()
    var regions: [CGRect] = []        // division + occlusion, active only
    var stripThickness: CGFloat = 56  // how deep each side slot is

    /// The usable rectangle for one side, inset by the safe area and
    /// shortened so it doesn't run into any reserved region.
    func rect(for side: Side, in size: CGSize) -> CGRect {
        let inner = CGRect(
            x: safeArea.leading,
            y: safeArea.top,
            width: size.width - safeArea.leading - safeArea.trailing,
            height: size.height - safeArea.top - safeArea.bottom
        )
        let t = stripThickness

        switch side {
        case .top:
            let strip = CGRect(x: inner.minX, y: inner.minY, width: inner.width, height: t)
            return carve(strip, horizontal: true)
        case .bottom:
            let strip = CGRect(x: inner.minX, y: inner.maxY - t, width: inner.width, height: t)
            return carve(strip, horizontal: true)
        case .leading:
            let strip = CGRect(x: inner.minX, y: inner.minY, width: t, height: inner.height)
            return carve(strip, horizontal: false)
        case .trailing:
            let strip = CGRect(x: inner.maxX - t, y: inner.minY, width: t, height: inner.height)
            return carve(strip, horizontal: false)
        }
    }

    /// Shrinks a strip along its length so it stops at the nearest reserved region.
    private func carve(_ strip: CGRect, horizontal: Bool) -> CGRect {
        let blockers: [ClosedRange<CGFloat>] = regions.compactMap { r in
            if horizontal {
                guard r.minY < strip.maxY, r.maxY > strip.minY else { return nil }
                return r.minX...r.maxX
            } else {
                guard r.minX < strip.maxX, r.maxX > strip.minX else { return nil }
                return r.minY...r.maxY
            }
        }
        let span = horizontal ? strip.minX...strip.maxX : strip.minY...strip.maxY
        let free = largestFreeSpan(span, blocked: blockers)
        let length = free.upperBound - free.lowerBound

        return horizontal
            ? CGRect(x: free.lowerBound, y: strip.minY, width: length, height: strip.height)
            : CGRect(x: strip.minX, y: free.lowerBound, width: strip.width, height: length)
    }
}

/// The largest part of `span` not covered by any blocked interval.
func largestFreeSpan(_ span: ClosedRange<CGFloat>, blocked: [ClosedRange<CGFloat>]) -> ClosedRange<CGFloat> {
    var best = span.lowerBound...span.lowerBound
    var cursor = span.lowerBound

    for b in blocked.sorted(by: { $0.lowerBound < $1.lowerBound }) {
        let gapEnd = min(b.lowerBound, span.upperBound)
        if gapEnd - cursor > best.upperBound - best.lowerBound {
            best = cursor...gapEnd
        }
        cursor = min(max(cursor, b.upperBound), span.upperBound)
    }
    if span.upperBound - cursor > best.upperBound - best.lowerBound {
        best = cursor...span.upperBound
    }
    return best
}

// MARK: - Environment plumbing

private struct EdgeLayoutKey: EnvironmentKey {
    static let defaultValue = EdgeLayout()
}

extension EnvironmentValues {
    var edgeLayout: EdgeLayout {
        get { self[EdgeLayoutKey.self] }
        set { self[EdgeLayoutKey.self] = newValue }
    }
}

// MARK: - Reader: publishes safe area and reserved regions

/// Reads the safe area and reserved regions once and makes them available
/// to every descendant through `@Environment(\.edgeLayout)`.
struct ReservedRegionReader<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        GeometryReader { proxy in
            let divisions = proxy.reservedRegions(kind: .division, options: .includeInactive)
            let occlusions = proxy.reservedRegions(kind: .occlusion, options: .includeInactive)

            let layout = EdgeLayout(
                safeArea: proxy.safeAreaInsets,
                regions: (Array(divisions) + Array(occlusions))
                    .filter(\.isActive)
                    .map(\.frame)
            )

            content()
                .environment(\.edgeLayout, layout)
        }
    }
}

// MARK: - Four side slots

/// Gives you one view per side, each sized to the free strip along that edge.
struct SideSlots<Content: View>: View {
    @Environment(\.edgeLayout) private var layout
    let content: (Side, CGRect) -> Content

    init(@ViewBuilder content: @escaping (Side, CGRect) -> Content) {
        self.content = content
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                ForEach(Side.allCases, id: \.self) { side in
                    let r = layout.rect(for: side, in: proxy.size)
                    content(side, r)
                        .frame(width: r.width, height: r.height, alignment: .topLeading)
                        .offset(x: r.minX, y: r.minY)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
        }
    }
}

// MARK: - Demo

struct SideDemoView: View {
    var body: some View {
        ReservedRegionReader {
            SideSlots { side, rect in
                Text("\(String(describing: side))\n\(Int(rect.width)) × \(Int(rect.height))")
                    .font(.caption.monospacedDigit())
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(color(for: side).opacity(0.25), in: RoundedRectangle(cornerRadius: 12))
                    .padding(4)
            }
        }
        .ignoresSafeArea()
    }

    private func color(for side: Side) -> Color {
        switch side {
        case .top: .blue
        case .bottom: .green
        case .leading: .orange
        case .trailing: .purple
        }
    }
}
