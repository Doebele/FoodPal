import SwiftUI
import SwiftData

/// Was die Anzeige gerade zeigt — und zugleich, womit die Erfassung öffnet.
enum DisplayMode: String {
    case kcal, mg
}

/// Der Startscreen. Tage werden **gewischt**, nicht über Pfeile geblättert;
/// der Bereich ist endlich (erster Eintrag bis heute), deshalb genügt ein
/// pagender `ScrollView` mit `LazyHStack`.
///
/// Die Kopfzeile steht **außerhalb** des Pagers: nur der Inhalt wandert,
/// Datum und Sprungziel bleiben stehen.
struct TodayView: View {
    @Query(sort: \Entry.date) private var all: [Entry]
    @AppStorage(Preference.captureMode) private var captureMode = Entry.Kind.coffee.rawValue
    @AppStorage(Preference.roast) private var roastRaw = Roast.hell.rawValue

    // Gleich auf heute gesetzt, nicht erst in onAppear — sonst feuert
    // beim Start ein Haptik-Impuls ohne Anlass.
    @State private var scrolled: Date? = Calendar.current.startOfDay(for: .now)

    private var calendar: Calendar { .current }
    private var today: Date { calendar.startOfDay(for: .now) }
    private var roast: Roast { Roast(rawValue: roastRaw) ?? .hell }
    private var mode: DisplayMode { captureMode == Entry.Kind.coffee.rawValue ? .mg : .kcal }

    /// Vom ersten Eintrag bis heute. Nach vorn ist bei heute Schluss —
    /// leere Zukunftstage wären nur Leerlauf.
    private var days: [Date] {
        let first = all.first.map { calendar.startOfDay(for: $0.date) } ?? today
        var out: [Date] = []
        var cursor = min(first, today)
        while cursor <= today {
            out.append(cursor)
            cursor = calendar.date(byAdding: .day, value: 1, to: cursor) ?? today.addingTimeInterval(1)
        }
        return out
    }

    private var currentDay: Date { scrolled ?? today }

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView(.horizontal) {
                LazyHStack(spacing: 0) {
                    ForEach(days, id: \.self) { day in
                        DayView(
                            entries: entries(on: day),
                            mode: mode,
                            roast: roast
                        )
                        .containerRelativeFrame(.horizontal)
                        .id(day)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $scrolled, anchor: .center)
            .scrollIndicators(.hidden)
            .haptic(.selection, trigger: currentDay)
        }
        .background(Palette.paper)
    }

    private var header: some View {
        ZStack {
            Text(title(for: currentDay))
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Palette.ink)

            // Der Sprung nach vorn erscheint nur, wenn er etwas tut.
            if currentDay != today {
                HStack {
                    Spacer()
                    Button {
                        withAnimation { scrolled = today }
                    } label: {
                        Text("Heute")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Palette.ink)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, Metric.margin)
        .padding(.top, 12)
        .padding(.bottom, 16)
    }

    private func title(for day: Date) -> String {
        if calendar.isDateInToday(day) { return "Heute" }
        if calendar.isDateInYesterday(day) { return "Gestern" }
        return day.formatted(.dateTime.day().month(.wide))
    }

    private func entries(on day: Date) -> [Entry] {
        all.filter { calendar.isDate($0.date, inSameDayAs: day) }
    }
}

/// Ein Tag: Diagramm, Trennlinie, Anzeige, Umschalter, Chronologie.
struct DayView: View {
    let entries: [Entry]
    let mode: DisplayMode
    let roast: Roast

    @AppStorage(Preference.captureMode) private var captureMode = Entry.Kind.coffee.rawValue
    @AppStorage(Preference.numberStyle) private var styleRaw = NumberStyle.flip.rawValue

    private var style: NumberStyle { NumberStyle(rawValue: styleRaw) ?? .flip }
    private var kcal: Int { Int(entries.reduce(0) { $0 + $1.kcal }.rounded()) }
    private var mg: Int { Int(entries.reduce(0) { $0 + $1.caffeineMg }.rounded()) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                hourLabels
                DayMatrix(entries: entries, roast: roast)
                    .padding(.top, 4)
                DottedRule()
                    .padding(.top, 14)

                NumberDisplay(
                    value: mode == .kcal ? kcal : mg,
                    style: style,
                    tint: mode == .kcal ? Palette.ink : roast.color
                )
                .frame(height: 112)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.top, 20)

                Text(mode == .kcal ? "kcal" : "mg")
                    .font(.system(size: 11))
                    .tracking(0.8)
                    .foregroundStyle(Palette.ink2)
                    .padding(.top, 10)

                ModeToggle(mode: mode, roast: roast) { new in
                    captureMode = new == .kcal ? Entry.Kind.meal.rawValue : Entry.Kind.coffee.rawValue
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 20)

                if entries.isEmpty {
                    Text("Noch nichts erfasst.")
                        .font(.system(size: 22, weight: .light))
                        .foregroundStyle(Palette.ink)
                        .padding(.top, 40)
                } else {
                    entryList.padding(.top, 32)
                }
            }
            .padding(.horizontal, Metric.margin)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
    }

    private var hourLabels: some View {
        GeometryReader { geo in
            let s = Grid.scale(forWidth: geo.size.width)
            ForEach(Array(stride(from: 0, to: 24, by: 4)), id: \.self) { hour in
                Text(String(format: "%02d", hour))
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(Palette.ink2)
                    .position(x: Grid.x(hour * 3) * s + 9, y: 7)
            }
        }
        .frame(height: 14)
    }

    private var entryList: some View {
        VStack(spacing: 0) {
            ForEach(entries.sorted { $0.date < $1.date }) { entry in
                HStack(spacing: 0) {
                    Text(entry.date.formatted(date: .omitted, time: .shortened))
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundStyle(Palette.ink2)
                        .frame(width: 52, alignment: .leading)
                    Text(entry.name)
                        .font(.system(size: 17))
                        .foregroundStyle(Palette.ink)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("\(Int(entry.kcal))")
                        .font(.system(size: 17, weight: .medium, design: .monospaced))
                        .foregroundStyle(Palette.ink)
                }
                .frame(height: Metric.rowHeight)
                .overlay(alignment: .bottom) {
                    Rectangle().fill(Palette.rule).frame(height: 1)
                }
            }
        }
    }
}

/// Umschalter kcal / mg. Er setzt zugleich den Modus der Erfassung —
/// Foto bei kcal, Getränkeauswahl bei mg.
struct ModeToggle: View {
    let mode: DisplayMode
    let roast: Roast
    let onChange: (DisplayMode) -> Void

    var body: some View {
        HStack(spacing: 0) {
            segment(.kcal, "kcal")
            segment(.mg, "mg")
        }
        .padding(4)
        .background(Capsule().fill(Palette.rule))
        .frame(width: 124, height: 40)
    }

    private func segment(_ target: DisplayMode, _ label: String) -> some View {
        let active = mode == target
        return Button { onChange(target) } label: {
            Text(label)
                .font(.system(size: 13, weight: active ? .medium : .regular))
                .foregroundStyle(active ? Palette.paper : Palette.ink2)
                .frame(width: 58, height: 32)
                .background {
                    if active {
                        Capsule().fill(target == .kcal ? Palette.ink : roast.color)
                    }
                }
        }
        .buttonStyle(.plain)
    }
}

/// Wählt die Ziffernanzeige nach der Einstellung. Ein `switch`, kein
/// Protokoll — drei konkrete Views, kein Erweiterungspunkt.
struct NumberDisplay: View {
    let value: Int
    let style: NumberStyle
    var tint: Color = Palette.ink

    var body: some View {
        switch style {
        case .flip:
            FlipDisplay(value: value, tint: tint)
        case .sevenSegment, .dotMatrix:
            // ponytail: Dot-Matrix-Ziffern folgen, sobald der Feinschliff
            // der Figma-Komponenten steht — bis dahin 7-Segment.
            SevenSegmentDisplay(value: value, tint: tint)
        }
    }
}
