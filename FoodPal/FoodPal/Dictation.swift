import AVFoundation
import Speech
import SwiftUI

/// Diktat auf Knopfdruck.
///
/// Die Systemtastatur kann das auch, aber nur, wenn man sie erst öffnet und
/// dann das Mikrofon darin findet. Auf dem Beschreiben-Schirm ist Sprache der
/// **Hauptweg**, nicht die Ausweichlösung — deshalb ein eigener Auslöser.
///
/// Der Text landet im selben Feld wie getippter Text und wird **nicht**
/// automatisch abgeschickt: Diktat verhört sich bei Essensnamen zuverlässig,
/// und ein Weg, der direkt aufnimmt und schätzt, würde den Fehler unsichtbar
/// weiterreichen. Man sieht, was ankam, und korrigiert vor dem Schätzen.
@Observable
final class Dictation {
    /// Was bisher verstanden wurde. Ersetzt beim Laufen den Feldinhalt ab der
    /// Stelle, an der das Diktat begonnen hat.
    private(set) var transcript = ""
    private(set) var isRunning = false
    private(set) var error: String?

    private let engine = AVAudioEngine()
    private var recognizer: SFSpeechRecognizer?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?

    /// Erkennt in der Sprache der App, nicht in der des Geräts — dieselbe
    /// Regel wie bei den Modellantworten.
    private static var locale: Locale {
        Locale(identifier: Locale.preferredLanguages.first ?? "de-DE")
    }

    var isAvailable: Bool {
        SFSpeechRecognizer(locale: Self.locale)?.isAvailable ?? false
    }

    func toggle() {
        isRunning ? stop() : start()
    }

    func start() {
        guard !isRunning else { return }
        error = nil

        Task { @MainActor in
            guard await Self.permitted() else {
                error = String(localized: "Zugriff auf Mikrofon oder Spracherkennung fehlt.")
                return
            }
            do { try begin() }
            catch { self.error = error.localizedDescription }
        }
    }

    func stop() {
        guard isRunning else { return }
        isRunning = false
        engine.stop()
        engine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        task?.cancel()
        request = nil
        task = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    // MARK: - Innenleben

    private func begin() throws {
        let recognizer = SFSpeechRecognizer(locale: Self.locale)
        guard let recognizer, recognizer.isAvailable else {
            throw Fehler.unavailable
        }
        self.recognizer = recognizer

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: .duckOthers)
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        // Auf dem Gerät, wo es geht: die Beschreibung einer Mahlzeit muss
        // Apples Server nicht sehen.
        request.requiresOnDeviceRecognition = recognizer.supportsOnDeviceRecognition
        self.request = request

        transcript = ""
        let input = engine.inputNode
        input.installTap(onBus: 0, bufferSize: 1024, format: input.outputFormat(forBus: 0)) { buffer, _ in
            request.append(buffer)
        }
        engine.prepare()
        try engine.start()
        isRunning = true

        task = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }
            if let result {
                transcript = result.bestTranscription.formattedString
            }
            // Ein Fehler nach dem Stoppen ist der Abbruch selbst — nicht melden.
            if error != nil || result?.isFinal == true {
                if isRunning, error != nil { self.error = error?.localizedDescription }
                stop()
            }
        }
    }

    private static func permitted() async -> Bool {
        let speech = await withCheckedContinuation { done in
            SFSpeechRecognizer.requestAuthorization { done.resume(returning: $0 == .authorized) }
        }
        guard speech else { return false }
        return await AVAudioApplication.requestRecordPermission()
    }

    private enum Fehler: LocalizedError {
        case unavailable
        var errorDescription: String? {
            String(localized: "Spracherkennung ist hier nicht verfügbar.")
        }
    }
}
