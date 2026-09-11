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
    let onCapture: () -> Void
    let onSettings: () -> Void

    @Query(sort: \Entry.date) private var all: [Entry]
    @AppStorage(Preference.captureMode) private var captureMode = Entry.Kind.coffee.rawValue
    @AppStorage(Preference.roast) private var roastRaw = Roast.hell.rawValue

    // Gleich auf heute gesetzt, nicht erst in onAppear — sonst feuert
    // beim Start ein Haptik-Impuls ohne Anlass.
    //
    // `START_DAY=-1` beginnt einen Tag frueher. Fuer die Bilder im App Store:
    // ein vergangener Tag ist **fertig gelaufen**, traegt also alle sechs
    // Eintraege — und er hat kein Jetzt, also auch keine Linie, die der
    // gesetzten Uhrzeit in der Statusleiste widersprechen koennte. Heute mit
    // fester Uhrzeit ginge auch, aber dann duerfte nichts nach dieser Uhrzeit
    // im Tag stehen, und uebrig bliebe ein fast leerer Zeitstrahl.
    @State private var scrolled: Date? = {
        let heute = Calendar.current.startOfDay(for: .now)
        #if DEBUG
        guard let roh = ProcessInfo.processInfo.environment["START_DAY"],
              let versatz = Int(roh) else { return heute }
        return Calendar.current.date(byAdding: .day, value: versatz, to: heute) ?? heute
        #else
        return heute
        #endif
    }()
    @State private var pickingDay = false

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

    @ViewBuilder private var calendar_: some View {
        if pickingDay {
            VStack(spacing: 0) {
                DayPicker(
                    selection: .constant(currentDay),
                    marked: markedDays,
                    range: (days.first ?? today)...today
                ) { day in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        scrolled = day
                        pickingDay = false
                    }
                }
                .padding(.horizontal, Metric.margin - 8)
                .padding(.bottom, 12)

                Rectangle().fill(Palette.rule).frame(height: 1)
            }
            .background(Palette.paper)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    /// Tage, an denen etwas steht — das ist die Markierung im Kalender.
    private var markedDays: Set<Date> {
        Set(all.map { calendar.startOfDay(for: $0.date) })
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView(.horizontal) {
                LazyHStack(spacing: 0) {
                    ForEach(days, id: \.self) { day in
                        DayView(
                            entries: entries(on: day),
                            mode: mode,
                            roast: roast,
                            isToday: calendar.isDateInToday(day)
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
            // Wer wischt, hat den Kalender nicht mehr noetig.
            .onChange(of: currentDay) { _, _ in
                if pickingDay { withAnimation(.easeInOut(duration: 0.2)) { pickingDay = false } }
            }
            // **Ueber** dem Tag, nicht davor: im Fluss haette der Kalender den
            // Zeitstrahl und die Anzeige zusammengeschoben, und man saehe von
            // dem Tag, den man gerade waehlt, nur noch einen Streifen.
            .overlay(alignment: .top) { calendar_ }
            // **Ueber** den Tag gelegt, nicht darunter gestellt: so laeuft die
            // Liste beim Scrollen hinter den Kacheln durch und scheint durchs
            // Glas hindurch. Ein `safeAreaInset` haelt den ruhenden Inhalt
            // trotzdem frei — nichts steht dauerhaft dahinter.
            .safeAreaInset(edge: .bottom, spacing: 0) { bottomBar }
        }
        .background(Palette.paper)
    }

    private var header: some View {
        ZStack {
            // Pfeile flankieren das Datum, damit es mittig bleibt —
            // unabhaengig davon, ob der Heute-Sprung gerade da ist.
            HStack(spacing: 4) {
                stepButton("<", delta: -1, enabled: canStep(-1))
                // Das Datum ist zugleich der Weg in die Vergangenheit: fuer
                // gestern wischt man, fuer „letzten Dienstag" waeren das ein
                // Dutzend Wischer.
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { pickingDay.toggle() }
                } label: {
                    Text(title(for: currentDay))
                        .scaledFont(14, weight: .medium)
                        .textCase(.lowercase)
                        .foregroundStyle(Palette.ink)
                        .frame(minWidth: 132)
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Tag wählen")
                .accessibilityValue(title(for: currentDay))
                stepButton(">", delta: 1, enabled: canStep(1))
            }

            HStack {
                Spacer()

                // Der Sprung nach vorn erscheint nur, wenn er etwas tut —
                // nach mehreren Tagen zurueck waere Vorwaertswischen muehsam.
                if currentDay != today {
                    Button {
                        withAnimation { scrolled = today }
                    } label: {
                        Text("Heute")
                            .scaledFont(13, weight: .medium)
                            .textCase(.lowercase)
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

    /// Deaktivierte Pfeile bleiben im Layout, aber unsichtbar: sonst
    /// wandert das Datum, sobald ein Rand erreicht ist.
    private func stepButton(_ glyph: String, delta: Int, enabled: Bool) -> some View {
        Button { step(delta) } label: {
            Text(glyph)
                .scaledFont(15)
                .foregroundStyle(Palette.ink2)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .opacity(enabled ? 1 : 0)
        .disabled(!enabled)
        .accessibilityLabel(delta < 0 ? "Vorheriger Tag" : "Nächster Tag")
    }

    private func canStep(_ delta: Int) -> Bool {
        guard let index = days.firstIndex(of: currentDay) else { return false }
        return days.indices.contains(index + delta)
    }

    private func step(_ delta: Int) {
        guard let index = days.firstIndex(of: currentDay),
              days.indices.contains(index + delta) else { return }
        withAnimation { scrolled = days[index + delta] }
    }

    /// **Alles Bedienbare liegt unten rechts.** Erfassen ist die Handlung des
    /// Schirms und bekommt die ganze Hoehe und das Zeichen; die Einstellungen
    /// stehen daneben, halb so hoch und ohne Zeichen — sie sind seltener
    /// gebraucht, und das soll man sehen, bevor man liest.
    ///
    /// Beide auf derselben Grundlinie, damit die Leiste eine Kante hat und
    /// nicht zwei. Aus dem Entwurf (Node `174:134657`).
    private var bottomBar: some View {
        HStack(alignment: .bottom, spacing: CaptureTile.gap) {
            Button(action: onSettings) {
                CaptureTile(label: "Einstellungen", height: 60, glass: true)
            }
            .buttonStyle(.plain)

            Button(action: onCapture) {
                CaptureTile(label: "Erfassen",
                            marks: [.plus(color: Palette.ink)],
                            height: 120,
                            glass: true)
            }
            .buttonStyle(.plain)
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal, Metric.margin)
        .padding(.bottom, CaptureTile.gap)
    }

    private func title(for day: Date) -> String {
        if calendar.isDateInToday(day) { return String(localized: "Heute") }
        if calendar.isDateInYesterday(day) { return String(localized: "Gestern") }
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
    /// Nur heute traegt die Jetzt-Kerbe.
    var isToday = false

    @AppStorage(Preference.captureMode) private var captureMode = Entry.Kind.coffee.rawValue
    @AppStorage(Preference.numberStyle) private var styleRaw = NumberStyle.flip.rawValue
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var selected: Entry?

    /// Rest-Aussenrand des Zeitstrahls. Nicht null: ganz bis zur Kante saehe
    /// nach Beschnitt aus statt nach Absicht.
    private static let timelineInset: CGFloat = 5

    /// Wo die Jetzt-Linie steht. Nur heute traegt sie eine.
    ///
    /// Im Debug-Build darf die Uhr stillstehen (`DEMO_NOW`): fuer das Bild im
    /// App Store, das heute zeigt. Die Statusleiste laesst sich stellen,
    /// `Date.now` nicht — sonst zeigte die eine neun Uhr und die andere den
    /// echten Nachmittag.
    private func now(_ tick: Date) -> Date? {
        guard isToday else { return nil }
        #if DEBUG
        return DemoData.pinnedNow(on: Calendar.current.startOfDay(for: tick)) ?? tick
        #else
        return tick
        #endif
    }

    private var style: NumberStyle { NumberStyle(rawValue: styleRaw) ?? .flip }
    private var kcal: Int { Int(entries.reduce(0) { $0 + $1.kcal }.rounded()) }
    private var mg: Int { Int(entries.reduce(0) { $0 + $1.caffeineMg }.rounded()) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Der Zeitstrahl laeuft aus dem Seitenrand heraus bis fast an
                // den Bildschirmrand. Beim Wischen von Tag zu Tag geht die
                // Rasterflaeche dadurch fliessend ineinander ueber, statt an
                // einer Kante abzubrechen.
                VStack(alignment: .leading, spacing: 0) {
                    hourLabels
                    // Die Linie soll wandern, ohne dass man die App neu
                    // oeffnet — einmal je Minute genuegt bei Viertelstunden.
                    TimelineView(.periodic(from: .now, by: 60)) { tick in
                        DayMatrix(
                            entries: entries,
                            roast: roast,
                            now: now(tick.date)
                        )
                    }
                    // Zwei Punkt Abstand wie bisher, minus die drei Einheiten,
                    // um die das Rasterfeld fuer den Ueberstand der Jetzt-Linie
                    // nach oben gewachsen ist. Die Punkte stehen damit, wo sie
                    // standen, und nur die Linie ragt in den Zwischenraum.
                    .padding(.top, -1)
                }
                .padding(.horizontal, -(Metric.margin - Self.timelineInset))

                // Die gepunktete Trennlinie ist weg: sie sass im alten Raster
                // mit einem Punkt je Stundengruppe und haette im neuen nur noch
                // eine zweite, groeber gerasterte Reihe unter dem Zeitstrahl
                // ergeben. Der Weissraum trennt genauso gut.
                numberDisplay

                // Keine Einheit neben der Zahl: der Umschalter direkt darunter
                // sagt bereits, ob kcal oder mg gemeint sind. Zweimal dasselbe
                // in zwei Zeilen ist eine Zeile zu viel.
                ModeToggle(mode: mode, roast: roast) { new in
                    captureMode = new == .kcal ? Entry.Kind.meal.rawValue : Entry.Kind.coffee.rawValue
                }
                .frame(maxWidth: .infinity)
                // Der Abstand nach oben steht bei jedem Stil in seinem eigenen
                // Zweig: die Dot-Matrix braucht mehr Luft als die Karten, und
                // ein gemeinsamer Wert hier haette den Umschalter bei einem der
                // beiden verrueckt.

                if entries.isEmpty {
                    Text("Noch nichts erfasst.")
                        .scaledFont(22, weight: .light)
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

    /// Nur noch vier Marken statt sechs — 02, 08, 14, 20. Ein Tag hat vier
    /// Sechserblöcke, und die Zahl steht am Anfang des zweiten davon; mehr
    /// Marken waren Lärm über einem Raster, das den Verlauf ohnehin zeigt.
    /// Die Dot-Matrix ist **dasselbe Raster** wie der Zeitstrahl, nur mit
    /// anderen Punkten beleuchtet — sie laeuft deshalb genauso bis an den Rand
    /// und bringt ihre Hoehe selbst mit. Flip und 7-Segment sind Schrift auf
    /// einer Flaeche und bleiben im Satzspiegel.
    @ViewBuilder private var numberDisplay: some View {
        let display = NumberDisplay(
            value: mode == .kcal ? kcal : mg,
            style: style,
            tint: mode == .kcal ? Palette.ink : roast.color,
            resetKey: mode.rawValue
        )
        if style == .dotMatrix {
            // Eine Rasterreihe Abstand, derselbe wie zwischen Koffein- und
            // Kalorienband: es ist dasselbe Feld, nur mit anderen Punkten.
            display
                .padding(.horizontal, -(Metric.margin - Self.timelineInset))
                .padding(.top, Grid.pitch)
                .padding(.bottom, 56)
        } else {
            // Zentriert, nicht rechtsbündig. Das Argument für rechts war, dass
            // die Einerstelle beim Wechsel von 1849 auf 206 stehen bleibt —
            // seit `Digits.of` immer vier Stellen zeigt, springt ohnehin
            // nichts, und mittig stehen Anzeige und Umschalter auf einer Achse.
            // Oben und unten gleich viel: die Anzeige steht mittig zwischen
            // Zeitstrahl und Umschalter, nicht nur mittig in der Breite.
            // 36 + 112 + 36 ist derselbe Gesamtabstand wie vorher — der
            // Umschalter bleibt, wo er war, die Anzeige rueckt in die Mitte.
            display
                .frame(height: 112)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 36)
        }
    }

    /// Drei Spalten in einer Zeile — bis die Schrift so gross wird, dass der
    /// Name dazwischen nur noch Stummel zeigt („Ofen ge…"). Ab den
    /// Bedienhilfen-Groessen ruecken Uhrzeit und Wert deshalb in eine eigene
    /// Zeile und der Name bekommt die ganze Breite: lieber zwei Zeilen als
    /// ein abgeschnittenes Wort.
    @ViewBuilder private func row(_ entry: Entry) -> some View {
        let time = Text(entry.date.formatted(date: .omitted, time: .shortened))
            .scaledFont(13, design: .monospaced)
            .foregroundStyle(Palette.ink2)
        let name = Text(entry.name)
            .scaledFont(17)
            .foregroundStyle(Palette.ink)
        let value = Text("\(Int(entry.kcal))")
            .scaledFont(17, weight: .medium, design: .monospaced)
            .foregroundStyle(Palette.ink)

        Group {
            if typeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        time
                        Spacer(minLength: 8)
                        value
                    }
                    name.frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                HStack(spacing: 8) {
                    // Die 52 pt der Uhrzeitspalte waren schon bei xxLarge zu
                    // eng — „19:15" wurde zu „1…".
                    time.fixedSize().frame(minWidth: 44, alignment: .leading)
                    name.lineLimit(2).frame(maxWidth: .infinity, alignment: .leading)
                    value.fixedSize()
                }
            }
        }
        .padding(.vertical, 10)
        .frame(minHeight: Metric.rowHeight)
        .contentShape(Rectangle())
    }

    private var hourLabels: some View {
        GeometryReader { geo in
            let s = Grid.scale(forWidth: geo.size.width)
            ForEach([2, 8, 14, 20], id: \.self) { hour in
                Text(String(format: "%02d", hour))
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(Palette.ink2)
                    .position(x: Grid.x(hour * Grid.perHour) * s + 7, y: 7)
            }
        }
        .frame(height: 14)
    }

    /// Neueste zuoberst. Die Liste steht unter der Tagessumme, und was man
    /// gerade erfasst hat, will man ohne Scrollen sehen — nicht am Ende eines
    /// langen Tages suchen. Das Diagramm darüber bleibt chronologisch; es ist
    /// eine Zeitachse und darf nicht rückwärts laufen.
    private var entryList: some View {
        VStack(spacing: 0) {
            ForEach(entries.sorted { $0.date > $1.date }) { entry in
                Button { selected = entry } label: { row(entry) }
                .buttonStyle(.plain)
                .overlay(alignment: .bottom) {
                    Rectangle().fill(Palette.rule).frame(height: 1)
                }
            }
        }
        // Zeile antippen oeffnet den Eintrag — der einzige Weg, ihn wieder
        // loszuwerden, seit Swipe-to-delete dem Tageswechsel weichen musste.
        .task {
            #if DEBUG
            // Erlaubt einen Screenshot des Eintrags ohne Bedienung des Simulators.
            switch ProcessInfo.processInfo.environment["START_ENTRY"] {
            case "1":
                let sorted = entries.sorted { $0.date < $1.date }
                // Bevorzugt einer mit Bild — sonst zeigt der Screenshot genau
                // den Teil nicht, um den es geht.
                selected = sorted.last { $0.photo != nil } ?? sorted.last
            case "coffee":
                // Ohne Foto: dann steht das mitgelieferte Bild der Sorte da,
                // und genau darum geht es bei diesem Schalter.
                selected = entries.sorted { $0.date < $1.date }
                    .last { $0.kind == .coffee && $0.photo == nil }
            default:
                break
            }
            #endif
        }
        .sheet(item: $selected) { entry in
            EntryDetailView(entry: entry)
                .presentationDragIndicator(.visible)
                .presentationDetents([.large])
                .presentationBackground(Palette.paper)
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
        // Beide Seiten sind Pillen, nicht nur die aktive: die ruhende liegt in
        // Papier auf der Kapsel und traegt ihre Beschriftung in der Farbe, um
        // die es dort geht — mg im Akzent des Koffeins. Vorher war sie blosser
        // Text auf grauem Grund und las sich wie ausgegraut.
        HStack(spacing: 4) {
            segment(.kcal, "kcal")
            segment(.mg, "mg")
        }
        .padding(4)
        .background(Capsule().fill(Palette.rule))
    }

    private func segment(_ target: DisplayMode, _ label: String) -> some View {
        let active = mode == target
        let accent = target == .mg ? roast.color : Palette.ink
        return Button { onChange(target) } label: {
            Text(label)
                .scaledFont(14, weight: .regular)
                .foregroundStyle(active ? Palette.ink3 : accent)
                // Feste 56 x 32 schnitten „kcal" bei grosser Schrift ab.
                // Jetzt legt der Text die Groesse fest, das Polster haelt die
                // Trefferflaeche.
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .frame(minWidth: 56)
                .background(Capsule().fill(active ? accent : Palette.paper))
        }
        .buttonStyle(.plain)
    }
}

/// Wählt die Ziffernanzeige nach der Einstellung. Ein `switch`, kein
/// Protokoll — drei konkrete Views, kein Erweiterungspunkt.
///
/// **Und die Stelle, an der der Wert wartet.** Wer einen Kaffee erfasst, sieht
/// den Wechsel sonst nicht: die Summe steht schon neu, während das Sheet noch
/// nach unten fährt. Die Bewegung findet hinter einer Fläche statt, die sie
/// verdeckt. Der Wert hinkt deshalb absichtlich hinterher, bis das Sheet weg
/// ist — die halbe Sekunde ist kurz genug, dass nichts hängt, und lang genug,
/// dass man hinschaut, bevor es losgeht.
struct NumberDisplay: View {
    let value: Int
    let style: NumberStyle
    var tint: Color = Palette.ink
    /// Wechselt dieser Schlüssel, nullt die Anzeige, statt weiterzuzählen.
    var resetKey: String = ""

    /// **0,3 s Sheet, 0,5 s Stille.** Nachgemessen an einer Bildschirmaufnahme:
    /// vom Tippen auf die Kaffeekachel bis zum verschwundenen Sheet vergehen
    /// rund drei Zehntel. Die halbe Sekunde danach ist der Moment, in dem der
    /// Blick schon auf der Anzeige liegt und sich noch nichts rührt — und
    /// genau dort setzt die Bewegung an. Mit 0,5 s insgesamt blieben nur zwei
    /// Zehntel Stille übrig, und der Aufbau begann, während das Auge noch dem
    /// Sheet nachsah.
    private static let delay = Duration.milliseconds(800)

    /// `nil`, solange nichts angezeigt wurde: der erste Wert geht ohne Warten
    /// durch. Das ist auch der Tageswechsel — jede Seite bringt ihre eigene
    /// Anzeige mit, und eine frisch erscheinende hat nichts zu verzögern.
    @State private var held: Int?
    @State private var heldKey = ""

    var body: some View {
        let shown = held ?? value
        Group {
            switch style {
            case .flip:
                FlipDisplay(value: shown, tint: tint, resetKey: resetKey)
            case .sevenSegment:
                SevenSegmentDisplay(value: shown, tint: tint, resetKey: resetKey)
            case .dotMatrix:
                DotMatrixDisplay(value: shown, tint: tint, resetKey: resetKey)
            }
        }
        .task(id: "\(value)|\(resetKey)") {
            // Der Moduswechsel geht sofort durch: man hat gerade auf den
            // Umschalter getippt und schaut die Anzeige an. Warten wäre dort
            // kein Auftritt, sondern eine Verzögerung.
            guard held != nil, resetKey == heldKey else {
                heldKey = resetKey
                held = value
                return
            }
            guard held != value else { return }
            try? await Task.sleep(for: Self.delay)
            guard !Task.isCancelled else { return }
            held = value
        }
    }
}
