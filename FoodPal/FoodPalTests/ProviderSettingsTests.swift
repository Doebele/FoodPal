import Testing
@testable import FoodPal

/// Der Punkt dieser Tests: **Wechseln darf nichts kosten.** Wer Claude
/// eingerichtet hat, kurz Gemini probiert und zurückwechselt, muss Claude
/// unverändert vorfinden — Modellname wie Adresse.
struct ProviderSettingsTests {

    @Test func werteBleibenJeAnbieterGetrennt() {
        var json = PerProvider.setting("{}", .claude, "claude-opus-4-5")
        json = PerProvider.setting(json, .gemini, "gemini-3-pro")

        #expect(PerProvider.value(json, .claude) == "claude-opus-4-5")
        #expect(PerProvider.value(json, .gemini) == "gemini-3-pro")
        #expect(PerProvider.value(json, .grok) == "")
    }

    @Test func hinUndZurueckVerliertNichts() {
        var json = PerProvider.setting("{}", .lmStudio, "http://192.168.1.77:1234/v1")
        json = PerProvider.setting(json, .ollama, "http://192.168.1.77:11434/v1")
        json = PerProvider.setting(json, .lmStudio, "http://192.168.1.77:1234/v1")

        #expect(PerProvider.value(json, .lmStudio) == "http://192.168.1.77:1234/v1")
        #expect(PerProvider.value(json, .ollama) == "http://192.168.1.77:11434/v1")
    }

    /// Feld leeren heisst „wieder die Vorgabe", nicht „leerer Modellname".
    @Test func leerenStelltVorgabeWiederHer() {
        var json = PerProvider.setting("{}", .claude, "claude-opus-4-5")
        json = PerProvider.setting(json, .claude, "")

        #expect(PerProvider.value(json, .claude) == "")
        #expect(Provider.claude.model(from: json) == Provider.claude.defaultModel)
    }

    @Test func kaputtesJSONFaelltStillAufLeerZurueck() {
        #expect(PerProvider.value("kein json", .claude) == "")
        #expect(Provider.claude.model(from: "kein json") == Provider.claude.defaultModel)
    }

    @Test func vorgabeGreiftNurOhneEigenenEintrag() {
        let json = PerProvider.setting("{}", .claude, "claude-opus-4-5")

        #expect(Provider.claude.model(from: json) == "claude-opus-4-5")
        #expect(Provider.gemini.model(from: json) == Provider.gemini.defaultModel)
    }

    /// Eine feste Anbieteradresse darf ein Eintrag nicht überschreiben —
    /// sonst zeigte ein Altwert aus dem Adressfeld auf den falschen Dienst.
    @Test func festeAdresseIstUnantastbar() {
        let json = PerProvider.setting("{}", .gemini, "http://irgendwo/v1")

        #expect(Provider.gemini.address(from: json) == Provider.gemini.fixedBaseURL)
        #expect(Provider.gemini.editableAddress == false)
    }

    @Test func freieAdresseNutztEintragSonstVorschlag() {
        let json = PerProvider.setting("{}", .ollama, "http://192.168.1.77:11434/v1")

        #expect(Provider.ollama.address(from: json) == "http://192.168.1.77:11434/v1")
        #expect(Provider.lmStudio.address(from: json) == Provider.lmStudio.defaultAddress)
    }

    /// Jeder Anbieter hat ein eigenes Keychain-Fach; zwei duerfen sich keins
    /// teilen, sonst ueberschreibt ein Wechsel den Schluessel des anderen.
    @Test func keychainFaecherSindEindeutig() {
        let accounts = Provider.allCases.map(\.keychainAccount)
        #expect(Set(accounts).count == accounts.count)
    }
}
