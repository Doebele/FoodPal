import SwiftUI
import SwiftData
import PhotosUI

/// Foto aufnehmen, schätzen lassen, bestätigen.
///
/// Vier Zustände, kein Assistent mit Schritten: aufnehmen, analysieren,
/// bestätigen, oder gescheitert. Der Weg zur manuellen Eingabe steht in
/// jedem davon offen.
struct PhotoCapture: View {
    let onSaved: () -> Void

    @Environment(\.modelContext) private var context
    @AppStorage(Preference.healthSync) private var healthSync = true
    @AppStorage(Preference.provider) private var providerRaw = Provider.claude.rawValue
    @AppStorage(Preference.model) private var model = ""
    @AppStorage(Preference.localURL) private var localURL = "http://192.168.1.42:1234/v1"

    @State private var health = HealthKitSync()
    @State private var phase = Phase.idle
    @State private var photoItem: PhotosPickerItem?
    @State private var showCamera = false
    @State private var saves = 0

    private enum Phase {
        case idle
        case analysing(UIImage)
        case ready(UIImage?, MealEstimate)
        case failed(UIImage?, String)
    }

    private var provider: Provider { Provider(rawValue: providerRaw) ?? .claude }
    private var effectiveModel: String { model.isEmpty ? provider.defaultModel : model }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            switch phase {
            case .idle: intake
            case .analysing(let image): analysing(image)
            case .ready(let image, let estimate): Confirm(image: image, estimate: estimate, onSave: save)
            case .failed(let image, let message): failure(image, message)
            }
        }
        .padding(.horizontal, Metric.margin)
        .haptic(trigger: saves)
        .photosPicker(isPresented: .constant(false), selection: $photoItem)
        .onChange(of: photoItem) { _, item in
            guard let item else { return }
            Task { await load(item) }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker { image in
                showCamera = false
                if let image { Task { await analyse(image) } }
            }
            .ignoresSafeArea()
        }
    }

    // MARK: - Aufnahme

    private var intake: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer(minLength: 0)

            Rectangle().fill(Palette.rule).frame(height: 1)
            action("Foto aufnehmen") { showCamera = true }
            PhotosPicker(selection: $photoItem, matching: .images) {
                rowLabel("Aus Fotos wählen")
            }
            .buttonStyle(.plain)
            .overlay(alignment: .bottom) { Rectangle().fill(Palette.rule).frame(height: 1) }
            action("Manuell eingeben") {
                phase = .ready(nil, MealEstimate(name: "", kcal: 0))
            }

            Text("Geschätzt wird von \(provider.label).")
                .font(.system(size: 11))
                .foregroundStyle(Palette.ink2)
                .padding(.top, 12)
        }
    }

    // MARK: - Analyse

    private func analysing(_ image: UIImage) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(height: 260)
                .clipped()
                .padding(.top, 12)

            ProgressDots().padding(.top, 14)

            Text("Analysiere")
                .font(.system(size: 22, weight: .light))
                .foregroundStyle(Palette.ink)
                .padding(.top, 18)
            Text(provider.label + " · " + effectiveModel)
                .font(.system(size: 13))
                .foregroundStyle(Palette.ink2)
                .padding(.top, 4)

            Spacer(minLength: 0)
        }
    }

    // MARK: - Fehler

    private func failure(_ image: UIImage?, _ message: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if let image {
                Image(uiImage: image)
                    .resizable().scaledToFill().frame(height: 180).clipped()
                    .padding(.top, 12)
            }
            Text("Schätzung fehlgeschlagen")
                .font(.system(size: 22, weight: .light))
                .foregroundStyle(Palette.ink)
                .padding(.top, 20)
            Text(message)
                .font(.system(size: 13))
                .foregroundStyle(Palette.ink2)
                .padding(.top, 6)

            Spacer(minLength: 0)

            Rectangle().fill(Palette.rule).frame(height: 1)
            if let image {
                action("Erneut versuchen") { Task { await analyse(image) } }
            }
            action("Manuell eingeben") {
                phase = .ready(image, MealEstimate(name: "", kcal: 0))
            }
        }
    }

    // MARK: - Bausteine

    private func action(_ title: String, run: @escaping () -> Void) -> some View {
        Button(action: run) { rowLabel(title) }
            .buttonStyle(.plain)
            .overlay(alignment: .bottom) { Rectangle().fill(Palette.rule).frame(height: 1) }
    }

    private func rowLabel(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(Palette.ink)
            Spacer()
        }
        .frame(height: 56)
        .contentShape(Rectangle())
    }

    // MARK: - Ablauf

    private func load(_ item: PhotosPickerItem) async {
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else { return }
        photoItem = nil
        await analyse(image)
    }

    private func analyse(_ image: UIImage) async {
        phase = .analysing(image)
        do {
            let estimate = try await VisionEstimator.estimate(
                image: image,
                provider: provider,
                model: effectiveModel,
                baseURL: localURL
            )
            phase = .ready(image, estimate)
        } catch {
            phase = .failed(image, error.localizedDescription)
        }
    }

    private func save(_ image: UIImage?, _ estimate: MealEstimate) {
        let entry = Entry(
            name: estimate.name.isEmpty ? "Mahlzeit" : estimate.name,
            kind: .meal,
            kcal: estimate.kcal,
            proteinG: estimate.proteinG,
            carbsG: estimate.carbsG,
            fatG: estimate.fatG,
            photo: image.flatMap { VisionEstimator.downscaled($0, maxEdge: 900) }
        )
        context.insert(entry)
        saves += 1

        if healthSync {
            Task { entry.hkIDs = (try? await health.save(entry)) ?? [] }
        }
        Task {
            try? await Task.sleep(for: .milliseconds(120))
            onSaved()
        }
    }
}

/// Bestätigung: alles ist änderbar, bevor es gespeichert wird. Eine Schätzung
/// aus einem Foto liegt realistisch daneben — der Schritt ist keine Höflichkeit.
private struct Confirm: View {
    let image: UIImage?
    let estimate: MealEstimate
    let onSave: (UIImage?, MealEstimate) -> Void

    @State private var name = ""
    @State private var kcal = ""
    @State private var protein = ""
    @State private var carbs = ""
    @State private var fat = ""
    @State private var loaded = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if let image {
                    Image(uiImage: image)
                        .resizable().scaledToFill().frame(height: 150).clipped()
                        .padding(.top, 12)
                        .padding(.bottom, 20)
                }

                field("bezeichnung", text: $name, mono: false)
                field("kcal", text: $kcal, mono: true)
                field("protein · g", text: $protein, mono: true)
                field("kohlenhydrate · g", text: $carbs, mono: true)
                field("fett · g", text: $fat, mono: true)

                Button {
                    onSave(image, MealEstimate(
                        name: name,
                        kcal: Double(kcal.replacingOccurrences(of: ",", with: ".")) ?? 0,
                        proteinG: Double(protein.replacingOccurrences(of: ",", with: ".")),
                        carbsG: Double(carbs.replacingOccurrences(of: ",", with: ".")),
                        fatG: Double(fat.replacingOccurrences(of: ",", with: "."))
                    ))
                } label: {
                    Text("Sichern")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(Palette.paper)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Palette.ink)
                }
                .buttonStyle(.plain)
                .padding(.top, 12)
            }
        }
        .scrollIndicators(.hidden)
        .task {
            guard !loaded else { return }
            name = estimate.name
            kcal = estimate.kcal > 0 ? String(Int(estimate.kcal)) : ""
            protein = estimate.proteinG.map { String(Int($0)) } ?? ""
            carbs = estimate.carbsG.map { String(Int($0)) } ?? ""
            fat = estimate.fatG.map { String(Int($0)) } ?? ""
            loaded = true
        }
    }

    private func field(_ label: String, text: Binding<String>, mono: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 11)).tracking(0.8)
                .foregroundStyle(Palette.ink2)
            TextField("", text: text)
                .keyboardType(mono ? .decimalPad : .default)
                .font(.system(size: 22, weight: .light, design: mono ? .monospaced : .default))
                .foregroundStyle(Palette.ink)
            Rectangle().fill(Palette.rule).frame(height: 1)
        }
        .padding(.bottom, 18)
    }
}

/// Fortschritt im Punktraster statt als Spinner — ein Balken, der durchläuft.
private struct ProgressDots: View {
    @State private var lit = 0
    private let total = 24

    var body: some View {
        Canvas { ctx, size in
            let s = size.width / (Grid.x(total - 1) + Grid.dot)
            for index in 0..<total {
                let rect = CGRect(x: Grid.x(index) * s, y: 0,
                                  width: Grid.dot * s, height: Grid.dot * s)
                ctx.fill(Path(rect), with: .color(index < lit ? Palette.ink : Palette.rule))
            }
        }
        .aspectRatio((Grid.x(total - 1) + Grid.dot) / Grid.dot, contentMode: .fit)
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(90))
                lit = lit >= total ? 0 : lit + 1
            }
        }
    }
}

/// Systemkamera in einem Wrapper — die eigene Kamera-Oberfläche zu bauen
/// wäre für ein Foto je Mahlzeit unverhältnismäßig.
struct CameraPicker: UIViewControllerRepresentable {
    let onResult: (UIImage?) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ controller: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onResult: onResult) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onResult: (UIImage?) -> Void
        init(onResult: @escaping (UIImage?) -> Void) { self.onResult = onResult }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            onResult(info[.originalImage] as? UIImage)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onResult(nil)
        }
    }
}
