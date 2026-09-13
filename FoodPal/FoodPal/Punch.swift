import CoreHaptics
import CoreMotion
import SwiftUI

/// **Woher das Licht kommt.** Die Lochungen ueber der Erfassung sind
/// Vertiefungen, und eine Vertiefung sieht erst dann nach einer aus, wenn ihr
/// Schatten sich mit dem Geraet dreht.
///
/// Oben in der Welt ist `-gravity`. Auf die Bildschirmebene projiziert und in
/// deren Koordinaten gedreht — dort zeigt y nach unten — ergibt das
/// `(-g.x, g.y)`. Aufrecht gehalten steht das Licht damit oben, flach auf dem
/// Tisch steht es senkrecht darueber und der Schatten wird ringsum gleich.
/// Beides stimmt mit dem ueberein, was ein Loch in echt tut.
///
/// Bewegungsdaten brauchen **keine** Berechtigung: `NSMotionUsageDescription`
/// verlangt nur der Schrittzaehler (`CMMotionActivityManager`).
///
/// Einer fuer die ganze App: Apple raet ausdruecklich von mehreren
/// `CMMotionManager` ab, und mehr als eine Lochplatte steht nie auf dem Schirm.
@MainActor
@Observable
final class Tilt {
    static let shared = Tilt()

    /// Richtung **zum Licht**, in Bildschirmkoordinaten. Betrag hoechstens 1.
    private(set) var light = CGVector(dx: 0, dy: -1)

    @ObservationIgnored private let motion = CMMotionManager()
    @ObservationIgnored private var leser = 0

    private init() {}

    /// Solange mindestens eine Lochplatte sichtbar ist, laeuft der Sensor.
    func subscribe() {
        leser += 1
        guard leser == 1, motion.isDeviceMotionAvailable else { return }
        // 30 Hz: der Schatten wandert langsam, und der Tiefpass darunter
        // glaettet ohnehin mehr weg, als 60 Hz hergaeben.
        motion.deviceMotionUpdateInterval = 1.0 / 30
        motion.startDeviceMotionUpdates(to: .main) { daten, _ in
            guard let g = daten?.gravity else { return }
            MainActor.assumeIsolated {
                let ziel = CGVector(dx: -g.x, dy: g.y)
                // Ohne Tiefpass zittert der Schatten bei jedem Puls im
                // Handgelenk. Ein Fuenftel je Messung ist traege genug, um
                // ruhig zu stehen, und schnell genug, um dem Kippen zu folgen.
                let alt = Tilt.shared.light
                let neu = CGVector(dx: alt.dx * 0.8 + ziel.dx * 0.2,
                                   dy: alt.dy * 0.8 + ziel.dy * 0.2)
                // Ein liegendes Geraet misst weiter, aber es aendert nichts.
                // Unter dieser Schwelle bleibt der Wert stehen, und die
                // Lochplatte zeichnet nicht dreissigmal je Sekunde dasselbe.
                guard abs(neu.dx - alt.dx) + abs(neu.dy - alt.dy) > 0.002 else { return }
                Tilt.shared.light = neu
            }
        }
    }

    func unsubscribe() {
        leser = max(0, leser - 1)
        guard leser == 0 else { return }
        motion.stopDeviceMotionUpdates()
        light = CGVector(dx: 0, dy: -1)
    }
}

/// **Eine Lochplatte statt gefuellter Punkte.**
///
/// Das Zeichen ist kein Papier, sondern ein Karton mit Dicke: die Punkte sind
/// durchgestanzt, und jede Stanzung hat eine Wand. In ein Loch faellt das
/// Licht auf die **abgewandte** Wand — die zugewandte verdeckt der Rand.
/// Genau diese Umkehrung trennt „eingestanzt" von „aufgesetzt"; ein Buckel
/// haette es andersherum.
///
/// Dahinter liegt ein zweites Blatt, das man durch die Loecher sieht. Beim
/// Diktieren wird es weggezogen, und die Loecher werden nacheinander schwarz,
/// weil dahinter nichts mehr ist. Der Rand der Oberflaeche bleibt stehen.
///
/// **`Animatable`, nicht `@State`:** ein `Canvas` zeichnet einmal je
/// Auswertung seines Body, und ein animierter Zustand kaeme dort fertig an,
/// nie dazwischen. Interpoliert wird deshalb `animatableData` dieser View.
struct PunchedArt: View, Animatable {
    /// Die Zeichnung — Punktmitten, Entwurfsquadrat, Punktdurchmesser.
    let art: DotArt
    /// Wie weit das hintere Blatt weggezogen ist: 0 liegt es, 1 ist es fort.
    var zug: CGFloat = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Wie lange das Blatt zum Wegziehen braucht. Steht hier, weil Bild und
    /// Haptik dieselbe Dauer haben muessen — sonst streicht es noch, wenn
    /// schon alles schwarz ist.
    static let dauer: TimeInterval = 0.55

    /// **Zehn Prozent groesser als im Entwurf.** Der Entwurf zeichnet
    /// Fuellungen, hier stehen Vertiefungen, und die Schattierung lebt allein
    /// in der Wand. Bei 6 pt sind das vier Pixel, in denen der ganze Effekt
    /// stattfinden muss. Der Zuschlag geht nach aussen, deshalb waechst
    /// unten auch das Entwurfsquadrat mit — sonst schnitte der `Canvas` den
    /// aeussersten Loechern eine Kante ab.
    static let wuchs: CGFloat = 1.1

    /// Wie weich die Kante des Blattes laeuft, in Entwurfseinheiten. Ein
    /// Fuenftel der Breite: die Loecher kippen als Welle, nicht als Linie.
    private static let weich: CGFloat = 40

    var animatableData: CGFloat {
        get { zug }
        set { zug = newValue }
    }

    var body: some View {
        // Das Licht wird **hier** gelesen, nicht in der Zeichenroutine: was
        // der Canvas-Verschluss liest, sieht SwiftUI nicht.
        let licht = reduceMotion ? CGVector(dx: 0, dy: -1) : Tilt.shared.light
        Canvas { ctx, size in
            // Der Zuschlag legt sich rund um jedes Loch, also auch um die
            // aeussersten: das Quadrat waechst um ihn, und die Punktmitten
            // ruecken um die Haelfte nach innen.
            let d = art.diameter * Self.wuchs
            let ueber = d - art.diameter
            let s = min(size.width, size.height) / (art.box + ueber)
            let versatz = ueber / 2 * s
            let r = d * s / 2
            // Die Wand frisst gut ein Drittel des Radius. Was uebrig
            // bleibt, ist der Boden.
            let wand = r * 0.42
            let laenge = min(1, hypot(licht.dx, licht.dy)) * wand * 0.9
            let o = CGSize(width: licht.dx * laenge, height: licht.dy * laenge)

            // Die Kante des hinteren Blattes, von links nach rechts.
            let kante = -Self.weich + zug * (art.box + 2 * Self.weich)

            for p in art.points {
                let c = CGPoint(x: p.x * s + versatz, y: p.y * s + versatz)

                // 1. Die Wand, beleuchtet.
                ctx.fill(kreis(c, r), with: .color(Palette.punchLight))

                // 2. Die Wand im Schatten: dieselbe Scheibe, zum Licht hin
                //    versetzt und um den Versatz verkleinert, damit sie
                //    nirgends ueber den Lochrand hinauslaeuft. Uebrig bleibt
                //    eine helle Sichel auf der lichtabgewandten Seite.
                ctx.fill(kreis(CGPoint(x: c.x + o.width, y: c.y + o.height),
                               r - laenge),
                         with: .color(Palette.punchDark))

                // 3. Der Boden. Schwarz, wenn das Blatt vorbei ist —
                //    darueber liegt das Blatt mit abnehmender Deckung.
                let boden = kreis(CGPoint(x: c.x - o.width * 0.3,
                                          y: c.y - o.height * 0.3),
                                  r - wand)
                ctx.fill(boden, with: .color(Palette.punchOpen))
                let deckung = 1 - Self.offen(p.x, kante: kante)
                if deckung > 0.001 {
                    ctx.fill(boden, with: .color(Palette.punchSheet.opacity(deckung)))
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityHidden(true)
        .onAppear { if !reduceMotion { Tilt.shared.subscribe() } }
        .onDisappear { if !reduceMotion { Tilt.shared.unsubscribe() } }
    }

    private func kreis(_ c: CGPoint, _ r: CGFloat) -> Path {
        Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r))
    }

    /// Wie weit ein Loch an der Stelle `x` schon frei liegt. Sanft statt
    /// linear: eine harte Rampe setzt eine sichtbare Kante quer durch die
    /// Rosette, wo keine sein soll.
    private static func offen(_ x: CGFloat, kante: CGFloat) -> CGFloat {
        let u = min(1, max(0, (kante - x) / weich))
        return u * u * (3 - 2 * u)
    }
}

/// **Das Blatt unter dem Daumen.**
///
/// Ein einzelner Impuls sagt „getippt". Das Wegziehen des Blattes dauert aber
/// eine halbe Sekunde und soll sich auch so lang anfuehlen. Dafuer reicht
/// `sensoryFeedback` nicht: das kennt Ereignisse, keine Dauer. CoreHaptics
/// kann beides, und es ist die einzige Stelle der App, die mehr braucht als
/// ein Einrasten.
@MainActor
final class SlideHaptic {
    static let shared = SlideHaptic()

    private var engine: CHHapticEngine?

    private init() {}

    /// **Die Maschine im Voraus anwerfen.** Ihr erster Start dauert einige
    /// Millisekunden. Wer damit bis zum Tippen wartet, verliert das erste
    /// Muster und merkt es erst beim zweiten.
    func prepare() {
        _ = laufwerk()
    }

    /// Ein an- und abschwellendes Streichen ueber `dauer`, am Ende ein leiser
    /// Anschlag: das Blatt ist da. Ohne Dauer bleibt nur der Anschlag — so
    /// klingt es, wenn „Bewegung reduzieren" die Fahrt wegnimmt.
    func play(dauer: TimeInterval) {
        guard UserDefaults.standard.bool(forKey: Preference.haptics),
              let engine = laufwerk()
        else { return }
        do {
            try engine.makePlayer(with: muster(dauer)).start(atTime: 0)
        } catch {
            // Haptik ist Beiwerk. Faellt sie aus, faellt sie aus.
            self.engine = nil
        }
    }

    private func laufwerk() -> CHHapticEngine? {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return nil }
        if let engine { return engine }
        do {
            let neu = try CHHapticEngine()
            // **Keine Tonspur.** Ohne das reserviert die Maschine
            // Audioressourcen, und neben der laufenden Aufnahme des Diktats
            // bekommt sie keine. Sie spielt dann einfach nicht.
            neu.playsHapticsOnly = true
            // iOS haelt sie an, wenn die App in den Hintergrund geht. Ohne
            // diese beiden Haender bleibt sie danach stumm.
            neu.resetHandler = { Task { @MainActor in try? SlideHaptic.shared.engine?.start() } }
            neu.stoppedHandler = { _ in Task { @MainActor in SlideHaptic.shared.engine = nil } }
            try neu.start()
            engine = neu
            return neu
        } catch {
            engine = nil
            return nil
        }
    }

    private func muster(_ dauer: TimeInterval) throws -> CHHapticPattern {
        let anschlag = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                .init(parameterID: .hapticIntensity, value: 0.4),
                .init(parameterID: .hapticSharpness, value: 0.6)
            ],
            relativeTime: max(0, dauer))
        guard dauer > 0 else { return try CHHapticPattern(events: [anschlag], parameters: []) }

        let streichen = CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [
                // Leise und stumpf: ein Blatt, das ueber ein anderes rutscht,
                // klickt nicht. Schaerfe 0,25 ist Reibung, nicht Rasterung.
                .init(parameterID: .hapticIntensity, value: 0.55),
                .init(parameterID: .hapticSharpness, value: 0.25)
            ],
            relativeTime: 0,
            duration: dauer)
        // Ohne Kurve steht ein gleichfoermiges Brummen da, und ein Blatt
        // zieht sich nicht gleichfoermig: es kommt in Fahrt und laeuft aus.
        let kurve = CHHapticParameterCurve(
            parameterID: .hapticIntensityControl,
            controlPoints: [
                .init(relativeTime: 0, value: 0),
                .init(relativeTime: dauer * 0.35, value: 1),
                .init(relativeTime: dauer, value: 0)
            ],
            relativeTime: 0)
        return try CHHapticPattern(events: [streichen, anschlag], parameterCurves: [kurve])
    }
}
