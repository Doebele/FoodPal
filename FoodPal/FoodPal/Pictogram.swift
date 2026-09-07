import SwiftUI

/// Piktogramme nach Otl Aicher: massive Flächen, runde Endkappen,
/// nur 0°, 45° und 90°. Durchgehend Strichstärke 2,4 und Radius 1,2
/// auf einem 24er-Raster — der Radius ist die halbe Strichstärke und
/// damit identisch mit dem Radius der Kappen.
///
/// Gezeichnet in einem `Canvas`, nicht aus Views zusammengesetzt:
/// eine Zeichnung statt eines Dutzends Formen je Glyphe.
struct Pictogram: View {
    enum Kind { case start, capture, coffee, profile, settings }

    let kind: Kind
    var color: Color = Palette.ink

    private static let stroke: CGFloat = 2.4
    private static let radius: CGFloat = 1.2

    var body: some View {
        Canvas { ctx, size in
            let s = min(size.width, size.height) / 24
            let style = StrokeStyle(lineWidth: Self.stroke * s, lineCap: .round, lineJoin: .round)

            func bar(_ points: [CGPoint]) {
                var p = Path()
                p.addLines(points.map { CGPoint(x: $0.x * s, y: $0.y * s) })
                ctx.stroke(p, with: .color(color), style: style)
            }
            func disc(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat, _ c: Color? = nil) {
                let rect = CGRect(x: (cx - r) * s, y: (cy - r) * s, width: r * 2 * s, height: r * 2 * s)
                ctx.fill(Path(ellipseIn: rect), with: .color(c ?? color))
            }
            func slab(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ c: Color? = nil) {
                let rect = CGRect(x: x * s, y: y * s, width: w * s, height: h * s)
                ctx.fill(Path(roundedRect: rect, cornerRadius: Self.radius * s), with: .color(c ?? color))
            }

            switch kind {
            case .start:
                for r in 0..<3 {
                    for c in 0..<3 {
                        slab(2 + CGFloat(c) * 7.5, 2 + CGFloat(r) * 7.5, 5.5, 5.5)
                    }
                }
            case .capture:
                slab(8, 4.5, 6, 4)
                slab(2, 7.5, 20, 12.5)
                disc(12, 13.75, 3.6, Palette.paper)
            case .coffee:
                slab(3, 6.5, 12, 10.5)
                bar([.init(x: 15.8, y: 9.5), .init(x: 19.5, y: 9.5),
                     .init(x: 19.5, y: 14), .init(x: 15.8, y: 14)])
                bar([.init(x: 2, y: 20), .init(x: 20, y: 20)])
            case .profile:
                disc(12, 6.8, 3.8)
                var p = Path()
                p.addLines([CGPoint(x: 3, y: 21), CGPoint(x: 3, y: 18), CGPoint(x: 8, y: 13),
                            CGPoint(x: 16, y: 13), CGPoint(x: 21, y: 18), CGPoint(x: 21, y: 21)]
                    .map { CGPoint(x: $0.x * s, y: $0.y * s) })
                p.closeSubpath()
                ctx.fill(p, with: .color(color))
            case .settings:
                bar([.init(x: 4, y: 6), .init(x: 20, y: 6)])
                bar([.init(x: 4, y: 12), .init(x: 20, y: 12)])
                bar([.init(x: 4, y: 18), .init(x: 20, y: 18)])
                disc(15.5, 6, 2.4)
                disc(8, 12, 2.4)
                disc(16.5, 18, 2.4)
            }
        }
        .accessibilityHidden(true)
    }
}

#Preview {
    HStack(spacing: 24) {
        ForEach([Pictogram.Kind.start, .capture, .coffee, .profile, .settings], id: \.self) { kind in
            Pictogram(kind: kind).frame(width: 48, height: 48)
        }
    }
    .padding()
    .background(Palette.paper)
}

extension Pictogram.Kind: Hashable {}
