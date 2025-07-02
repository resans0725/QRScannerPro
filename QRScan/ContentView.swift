import SwiftUI
import AVFoundation
import Vision
import VisionKit
import CoreImage
import CoreImage.CIFilterBuiltins

// MARK: - Models
struct QRScanResult: Identifiable, Codable {
    let id = UUID()
    let content: String
    let timestamp: Date
    let type: QRType
    
    enum QRType: String, CaseIterable, Codable {
        case url = "URL"
        case text = "テキスト"
        case email = "メール"
        case phone = "電話"
        case wifi = "Wi-Fi"
        case unknown = "その他"
        
        var icon: String {
            switch self {
            case .url: return "safari.fill"
            case .text: return "text.bubble.fill"
            case .email: return "envelope.fill"
            case .phone: return "phone.fill"
            case .wifi: return "wifi"
            case .unknown: return "qrcode"
            }
}

// MARK: - Photo Scanner View
struct PhotoScannerView: View {
    @ObservedObject var viewModel: QRScannerViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingImagePicker = false
    @State private var inputImage: UIImage?
    
    var body: some View {
        NavigationView {
            ZStack {
                GlassmorphismBackground()
                
                VStack(spacing: 30) {
                    Spacer()
                    
                    // アイコン
                    Image(systemName: "photo.on.rectangle")
                        .font(.system(size: 80))
                        .foregroundColor(.orange)
                    
                    Text("写真からQRコードを読み取り")
                        .font(.title2.bold())
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                    
                    Text("カメラロールから写真を選択して\nQRコードをスキャンできます")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                    
                    Spacer()
                    
                    // 選択ボタン
                    Button("写真を選択") {
                        showingImagePicker = true
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .tint(.orange)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("写真からスキャン")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $inputImage)
            }
            .onChange(of: inputImage) { newImage in
                if let image = newImage {
                    viewModel.scanQRFromImage(image)
                    dismiss()
                }
            }
        }
    }
}

// MARK: - QR Generator View
struct QRGeneratorView: View {
    @ObservedObject var viewModel: QRScannerViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var inputText = ""
    @State private var selectedType: QRGeneratorType = .text
    @State private var showingShareSheet = false
    
    enum QRGeneratorType: String, CaseIterable {
        case text = "テキスト"
        case url = "URL"
        case email = "メール"
        case phone = "電話番号"
        case wifi = "Wi-Fi"
        
        var icon: String {
            switch self {
            case .text: return "text.bubble"
            case .url: return "safari"
            case .email: return "envelope"
            case .phone: return "phone"
            case .wifi: return "wifi"
            }
        }
        
        var placeholder: String {
            switch self {
            case .text: return "テキストを入力..."
            case .url: return "https://example.com"
            case .email: return "example@email.com"
            case .phone: return "090-1234-5678"
            case .wifi: return "WIFI:T:WPA;S:ネットワーク名;P:パスワード;;"
            }
        }
        
        var color: Color {
            switch self {
            case .text: return .green
            case .url: return .blue
            case .email: return .orange
            case .phone: return .purple
            case .wifi: return .cyan
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                GlassmorphismBackground()
                
                ScrollView {
                    VStack(spacing: 30) {
                        // タイプ選択
                        GlassCard {
                            VStack(alignment: .leading, spacing: 15) {
                                Text("QRコードの種類")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 15) {
                                        ForEach(QRGeneratorType.allCases, id: \.self) { type in
                                            Button(action: {
                                                selectedType = type
                                                inputText = ""
                                            }) {
                                                VStack(spacing: 8) {
                                                    Image(systemName: type.icon)
                                                        .font(.title2)
                                                        .foregroundColor(
                                                            selectedType == type ? .white : type.color
                                                        )
                                                    
                                                    Text(type.rawValue)
                                                        .font(.caption.bold())
                                                        .foregroundColor(
                                                            selectedType == type ? .white : type.color
                                                        )
                                                }
                                                .frame(width: 70, height: 70)
                                                .background(
                                                    selectedType == type ?
                                                    type.color : type.color.opacity(0.1)
                                                )
                                                .cornerRadius(15)
                                                .animation(.spring(response: 0.3), value: selectedType)
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                        
                        // テキスト入力
                        GlassCard {
                            VStack(alignment: .leading, spacing: 15) {
                                Text("内容を入力")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                TextField(selectedType.placeholder, text: $inputText, axis: .vertical)
                                    .textFieldStyle(.roundedBorder)
                                    .lineLimit(3...6)
                            }
                        }
                        
                        // QRコード生成・表示
                        if !inputText.isEmpty {
                            GlassCard {
                                VStack(spacing: 20) {
                                    Text("生成されたQRコード")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    if let qrImage = viewModel.generateQRCode(from: formatText(inputText, for: selectedType)) {
                                        Image(uiImage: qrImage)
                                            .interpolation(.none)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 200, height: 200)
                                            .background(.white)
                                            .cornerRadius(15)
                                            .onTapGesture {
                                                viewModel.generatedQRCode = qrImage
                                                showingShareSheet = true
                                            }
                                        
                                        Text("タップして共有")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding()
                }
            }
            .navigationTitle("QRコード作成")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let qrImage = viewModel.generatedQRCode {
                    ShareSheet(items: [qrImage])
                }
            }
        }
    }
    
    private func formatText(_ text: String, for type: QRGeneratorType) -> String {
        switch type {
        case .url:
            if !text.hasPrefix("http://") && !text.hasPrefix("https://") {
                return "https://" + text
            }
            return text
        case .email:
            if !text.hasPrefix("mailto:") {
                return "mailto:" + text
            }
            return text
        case .phone:
            if !text.hasPrefix("tel:") {
                return "tel:" + text
            }
            return text
        default:
            return text
        }
    }
}

// MARK: - Helper Views
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
        }
        
        var color: Color {
            switch self {
            case .url: return .blue
            case .text: return .green
            case .email: return .orange
            case .phone: return .purple
            case .wifi: return .cyan
            case .unknown: return .gray
            }
        }
    }
    
    static func determineType(from content: String) -> QRType {
        if content.starts(with: "http://") || content.starts(with: "https://") {
            return .url
        } else if content.starts(with: "mailto:") {
            return .email
        } else if content.starts(with: "tel:") || content.starts(with: "phone:") {
            return .phone
        } else if content.starts(with: "WIFI:") {
            return .wifi
        } else if content.contains("@") && content.contains(".") {
            return .email
        } else {
            return .text
        }
    }
}

// MARK: - ViewModels
class QRScannerViewModel: ObservableObject {
    @Published var scannedResults: [QRScanResult] = []
    @Published var isScanning = false
    @Published var showingScanner = false
    @Published var showingPhotoScanner = false
    @Published var showingQRGenerator = false
    @Published var lastScannedCode: String = ""
    @Published var showingResult = false
    @Published var generatedQRCode: UIImage?
    @Published var qrGeneratorText: String = ""
    
    private let userDefaults = UserDefaults.standard
    private let resultsKey = "QRScanResults"
    
    init() {
        loadResults()
    }
    
    func addResult(_ content: String) {
        let type = QRScanResult.determineType(from: content)
        let result = QRScanResult(content: content, timestamp: Date(), type: type)
        
        // 重複チェック
        if !scannedResults.contains(where: { $0.content == content }) {
            scannedResults.insert(result, at: 0)
            saveResults()
            lastScannedCode = content
            showingResult = true
        }
    }
    
    func deleteResult(_ result: QRScanResult) {
        scannedResults.removeAll { $0.id == result.id }
        saveResults()
    }
    
    func clearAllResults() {
        scannedResults.removeAll()
        saveResults()
    }
    
    func generateQRCode(from text: String) -> UIImage? {
        // UTF-8エンコーディングを使用して日本語に対応
        let data = text.data(using: .utf8)
        
        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            // エラー訂正レベルを高に設定
            filter.setValue("H", forKey: "inputCorrectionLevel")
            
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            
            if let output = filter.outputImage?.transformed(by: transform) {
                let context = CIContext()
                if let cgImage = context.createCGImage(output, from: output.extent) {
                    return UIImage(cgImage: cgImage)
                }
            }
        }
        return nil
    }
    
    func scanQRFromImage(_ image: UIImage) {
        guard let cgImage = image.cgImage else { return }
        
        let request = VNDetectBarcodesRequest { [weak self] request, error in
            guard let results = request.results as? [VNBarcodeObservation] else { return }
            
            DispatchQueue.main.async {
                if let firstResult = results.first,
                   let payload = firstResult.payloadStringValue {
                    self?.addResult(payload)
                }
            }
        }
        
        let handler = VNImageRequestHandler(cgImage: cgImage)
        try? handler.perform([request])
    }
    
    private func saveResults() {
        if let encoded = try? JSONEncoder().encode(scannedResults) {
            userDefaults.set(encoded, forKey: resultsKey)
        }
    }
    
    private func loadResults() {
        if let data = userDefaults.data(forKey: resultsKey),
           let decoded = try? JSONDecoder().decode([QRScanResult].self, from: data) {
            scannedResults = decoded
        }
    }
}

// MARK: - Camera Scanner
struct QRScannerView: UIViewControllerRepresentable {
    @Binding var scannedCode: String
    @Binding var isScanning: Bool
    var onCodeScanned: (String) -> Void
    
    func makeUIViewController(context: Context) -> QRScannerViewController {
        let controller = QRScannerViewController()
        controller.delegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: QRScannerViewController, context: Context) {
        if isScanning {
            uiViewController.startScanning()
        } else {
            uiViewController.stopScanning()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, QRScannerDelegate {
        let parent: QRScannerView
        
        init(_ parent: QRScannerView) {
            self.parent = parent
        }
        
        func didScanCode(_ code: String) {
            parent.scannedCode = code
            parent.onCodeScanned(code)
        }
    }
}

protocol QRScannerDelegate: AnyObject {
    func didScanCode(_ code: String)
}

class QRScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    weak var delegate: QRScannerDelegate?
    private var captureSession: AVCaptureSession!
    private var previewLayer: AVCaptureVideoPreviewLayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
    }
    
    private func setupCamera() {
        captureSession = AVCaptureSession()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            return
        }
        
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }
        
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            return
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
    }
    
    func startScanning() {
        if !captureSession.isRunning {
            DispatchQueue.global(qos: .background).async {
                self.captureSession.startRunning()
            }
        }
    }
    
    func stopScanning() {
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            delegate?.didScanCode(stringValue)
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        previewLayer?.frame = view.layer.bounds
    }
}

// MARK: - Custom Views
struct GlassmorphismBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.purple.opacity(0.3),
                    Color.blue.opacity(0.4),
                    Color.cyan.opacity(0.3)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // バブルエフェクト
            ForEach(0..<6, id: \.self) { i in
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.1), Color.white.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: CGFloat.random(in: 100...200))
                    .position(
                        x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                        y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                    )
                    .animation(
                        Animation.easeInOut(duration: Double.random(in: 3...6))
                            .repeatForever(autoreverses: true),
                        value: i
                    )
            }
        }
    }
}

struct GlassCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.3), Color.white.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
    }
}

struct PulsingButton: View {
    let action: () -> Void
    let icon: String
    let title: String
    let color: Color
    @State private var isPulsing = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 80, height: 80)
                        .scaleEffect(isPulsing ? 1.2 : 1.0)
                        .opacity(isPulsing ? 0.5 : 1.0)
                        .animation(
                            Animation.easeInOut(duration: 1.5)
                                .repeatForever(autoreverses: true),
                            value: isPulsing
                        )
                    
                    Image(systemName: icon)
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(color)
                }
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
            }
        }
        .onAppear {
            isPulsing = true
        }
    }
}

// MARK: - Main Views
struct ContentView: View {
    @StateObject private var viewModel = QRScannerViewModel()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(viewModel: viewModel)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("ホーム")
                }
                .tag(0)
            
            HistoryView(viewModel: viewModel)
                .tabItem {
                    Image(systemName: "clock.fill")
                    Text("履歴")
                }
                .tag(1)
        }
        .accentColor(.cyan)
        .sheet(isPresented: $viewModel.showingScanner) {
            ScannerModalView(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showingPhotoScanner) {
            PhotoScannerView(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showingQRGenerator) {
            QRGeneratorView(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showingResult) {
            ResultModalView(viewModel: viewModel)
        }
    }
}

struct HomeView: View {
    @ObservedObject var viewModel: QRScannerViewModel
    
    var body: some View {
        ZStack {
            GlassmorphismBackground()
            
            VStack(spacing: 40) {
                Spacer()
                
                // アプリタイトル
                VStack(spacing: 10) {
                    Text("QR Scanner Pro")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.cyan, .blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Text("Scan • Create • Share")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .tracking(2)
                }
                
                Spacer()
                
                // メインボタン
                GlassCard {
                    VStack(spacing: 30) {
                        PulsingButton(
                            action: {
                                viewModel.showingScanner = true
                            },
                            icon: "qrcode.viewfinder",
                            title: "QRコードをスキャン",
                            color: .cyan
                        )
                        
                        HStack(spacing: 40) {
                            PulsingButton(
                                action: {
                                    viewModel.showingPhotoScanner = true
                                },
                                icon: "photo",
                                title: "写真から読取",
                                color: .orange
                            )
                            
                            PulsingButton(
                                action: {
                                    viewModel.showingQRGenerator = true
                                },
                                icon: "qrcode",
                                title: "QR作成",
                                color: .green
                            )
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // 統計情報
                if !viewModel.scannedResults.isEmpty {
                    GlassCard {
                        HStack {
                            VStack {
                                Text("\(viewModel.scannedResults.count)")
                                    .font(.title.bold())
                                    .foregroundColor(.cyan)
                                Text("スキャン回数")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            VStack {
                                Text("今日")
                                    .font(.title.bold())
                                    .foregroundColor(.purple)
                                Text("最後のスキャン")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
            }
        }
    }
}

struct HistoryView: View {
    @ObservedObject var viewModel: QRScannerViewModel
    @State private var searchText = ""
    
    var filteredResults: [QRScanResult] {
        if searchText.isEmpty {
            return viewModel.scannedResults
        } else {
            return viewModel.scannedResults.filter { result in
                result.content.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                GlassmorphismBackground()
                
                VStack {
                    if viewModel.scannedResults.isEmpty {
                        emptyStateView
                    } else {
                        historyListView
                    }
                }
            }
            .navigationTitle("スキャン履歴")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "履歴を検索")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !viewModel.scannedResults.isEmpty {
                        Button("全削除") {
                            viewModel.clearAllResults()
                        }
                        .foregroundColor(.red)
                    }
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "qrcode")
                .font(.system(size: 80))
                .foregroundColor(.gray.opacity(0.5))
            
            Text("まだスキャンしていません")
                .font(.title2.bold())
                .foregroundColor(.secondary)
            
            Text("QRコードをスキャンすると\nここに履歴が表示されます")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
            
            Spacer()
        }
    }
    
    private var historyListView: some View {
        List {
            ForEach(filteredResults) { result in
                HistoryRowView(result: result) {
                    viewModel.deleteResult(result)
                }
            }
        }
        .listStyle(.plain)
        .background(.clear)
    }
}

struct HistoryRowView: View {
    let result: QRScanResult
    let onDelete: () -> Void
    @State private var showingActionSheet = false
    @State private var showingDeleteAlert = false
    @State private var showingCopyAlert = false
    
    var body: some View {
        VStack(spacing: 0) {
            // メインコンテンツ（タップ判定なし）
            HStack(spacing: 15) {
                // アイコン
                ZStack {
                    Circle()
                        .fill(result.type.color.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: result.type.icon)
                        .font(.title3)
                        .foregroundColor(result.type.color)
                }
                
                // コンテンツ
                VStack(alignment: .leading, spacing: 6) {
                    Text(result.type.rawValue)
                        .font(.caption.bold())
                        .foregroundColor(result.type.color)
                    
                    Text(result.content)
                        .font(.body)
                        .lineLimit(2)
                        .foregroundColor(.primary)
                    
                    Text(result.timestamp, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // 詳細ボタン
                Button(action: {
                    showingActionSheet = true
                }) {
                    Image(systemName: "ellipsis")
                        .font(.title2)
                        .foregroundColor(.secondary)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(Color.gray.opacity(0.1)))
                }
                .buttonStyle(PlainButtonStyle()) // ボタンスタイル明示
            }
            
            // アクションボタン行
            HStack(spacing: 12) {
                // コピーボタン
                Button(action: {
                    copyToClipboard()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "doc.on.doc.fill")
                            .font(.system(size: 14, weight: .medium))
                        Text("コピー")
                            .font(.caption.bold())
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(20)
                }
                .buttonStyle(PlainButtonStyle()) // ボタンスタイル明示
                
                // ブラウザで開くボタン
                if isValidURL(result.content) {
                    Button(action: {
                        openInBrowser(result.content)
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "safari.fill")
                                .font(.system(size: 14, weight: .medium))
                            Text("開く")
                                .font(.caption.bold())
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            LinearGradient(
                                colors: [.green, .mint],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(20)
                    }
                    .buttonStyle(PlainButtonStyle()) // ボタンスタイル明示
                }
                
                Spacer()
                
                // 削除ボタン
                Button(action: {
                    showingDeleteAlert = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 14, weight: .medium))
                        Text("削除")
                            .font(.caption.bold())
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        LinearGradient(
                            colors: [.red, .pink],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(20)
                }
                .buttonStyle(PlainButtonStyle()) // ボタンスタイル明示
            }
            .padding(.top, 12)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.3), Color.white.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
        .confirmationDialog(
            "アクション選択",
            isPresented: $showingActionSheet,
            titleVisibility: .visible
        ) {
            Button("コピー") {
                copyToClipboard()
            }
            
            if isValidURL(result.content) {
                Button("ブラウザで開く") {
                    openInBrowser(result.content)
                }
            }
            
            Button("共有") {
                shareContent(result.content)
            }
            
            Button("削除", role: .destructive) {
                showingDeleteAlert = true
            }
            
            Button("キャンセル", role: .cancel) { }
        }
        .alert("コピーしました", isPresented: $showingCopyAlert) {
            Button("OK") { }
        } message: {
            Text("クリップボードにコピーされました")
        }
        .alert("削除しますか？", isPresented: $showingDeleteAlert) {
            Button("削除", role: .destructive) {
                deleteItem()
            }
            Button("キャンセル", role: .cancel) { }
        } message: {
            Text("この履歴を削除してもよろしいですか？")
        }
    }
    
    private func copyToClipboard() {
        UIPasteboard.general.string = result.content
        
        // 触覚フィードバック
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // コピー完了アラート表示
        showingCopyAlert = true
    }
    
    private func deleteItem() {
        // 削除の触覚フィードバック
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            onDelete()
        }
    }
    
    private func isValidURL(_ string: String) -> Bool {
        // URLかどうかをチェック
        if string.hasPrefix("http://") || string.hasPrefix("https://") {
            return URL(string: string) != nil
        }
        // ドメイン名っぽい場合もOK
        if string.contains(".") && !string.contains(" ") && string.count > 3 {
            return true
        }
        return false
    }
    
    private func openInBrowser(_ urlString: String) {
        var finalURL: URL?
        
        if let url = URL(string: urlString) {
            finalURL = url
        } else if urlString.contains(".") && !urlString.hasPrefix("http") {
            // httpがついてない場合は自動で追加
            finalURL = URL(string: "https://" + urlString)
        }
        
        if let url = finalURL {
            UIApplication.shared.open(url)
        }
    }
    
    private func shareContent(_ content: String) {
        let activityVC = UIActivityViewController(
            activityItems: [content],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityVC, animated: true)
        }
    }
}


struct ScannerModalView: View {
    @ObservedObject var viewModel: QRScannerViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            QRScannerView(
                scannedCode: $viewModel.lastScannedCode,
                isScanning: $viewModel.isScanning
            ) { code in
                viewModel.addResult(code)
                viewModel.isScanning = false
                dismiss()
            }
            
            VStack {
                HStack {
                    Button("キャンセル") {
                        viewModel.isScanning = false
                        dismiss()
                    }
                    .foregroundColor(.white)
                    .padding()
                    
                    Spacer()
                }
                
                Spacer()
                
                // スキャンエリア
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.cyan, lineWidth: 3)
                    .frame(width: 250, height: 250)
                    .overlay(
                        VStack {
                            Spacer()
                            Text("QRコードをここに合わせてください")
                                .foregroundColor(.white)
                                .font(.headline)
                                .padding()
                                .background(.ultraThinMaterial)
                                .cornerRadius(10)
                        }
                    )
                
                Spacer()
            }
        }
        .onAppear {
            viewModel.isScanning = true
        }
        .onDisappear {
            viewModel.isScanning = false
        }
    }
}

struct ResultModalView: View {
    @ObservedObject var viewModel: QRScannerViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                GlassmorphismBackground()
                
                VStack(spacing: 30) {
                    // 成功アニメーション
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.green)
                        .scaleEffect(1.2)
                        .animation(.spring(response: 0.6, dampingFraction: 0.6), value: viewModel.showingResult)
                    
                    Text("スキャン完了！")
                        .font(.title.bold())
                        .foregroundColor(.primary)
                    
                    // 結果表示
                    GlassCard {
                        VStack(alignment: .leading, spacing: 15) {
                            Text("スキャン結果")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text(viewModel.lastScannedCode)
                                .font(.body)
                                .foregroundColor(.primary)
                                .padding()
                                .background(.ultraThinMaterial)
                                .cornerRadius(10)
                        }
                    }
                    
                    // アクションボタン
                    HStack(spacing: 30) {
                        // コピーボタン
                        Button(action: {
                            UIPasteboard.general.string = viewModel.lastScannedCode
                        }) {
                            VStack(spacing: 8) {
                                Image(systemName: "doc.on.doc.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                Text("コピー")
                                    .font(.caption.bold())
                                    .foregroundColor(.white)
                            }
                            .frame(width: 80, height: 80)
                            .background(
                                LinearGradient(
                                    colors: [.blue, .cyan],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(20)
                        }
                        
                        // ブラウザで開くボタン
                        Button(action: {
                            if let url = URL(string: viewModel.lastScannedCode) {
                                UIApplication.shared.open(url)
                            } else if viewModel.lastScannedCode.contains(".") && !viewModel.lastScannedCode.hasPrefix("http") {
                                // httpがついてない場合は自動で追加
                                if let url = URL(string: "https://" + viewModel.lastScannedCode) {
                                    UIApplication.shared.open(url)
                                }
                            }
                        }) {
                            VStack(spacing: 8) {
                                Image(systemName: "safari.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                Text("開く")
                                    .font(.caption.bold())
                                    .foregroundColor(.white)
                            }
                            .frame(width: 80, height: 80)
                            .background(
                                LinearGradient(
                                    colors: [.orange, .red],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(20)
                        }
                        .disabled(!isValidURL(viewModel.lastScannedCode))
                        .opacity(isValidURL(viewModel.lastScannedCode) ? 1.0 : 0.5)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("スキャン結果")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func isValidURL(_ string: String) -> Bool {
        // URLかどうかをチェック
        if string.hasPrefix("http://") || string.hasPrefix("https://") {
            return URL(string: string) != nil
        }
        // ドメイン名っぽい場合もOK
        if string.contains(".") && !string.contains(" ") {
            return true
        }
        return false
    }
}

// MARK: - Photo Scanner View
struct PhotoScannerView: View {
    @ObservedObject var viewModel: QRScannerViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingImagePicker = false
    @State private var inputImage: UIImage?
    
    var body: some View {
        NavigationView {
            ZStack {
                GlassmorphismBackground()
                
                VStack(spacing: 30) {
                    Spacer()
                    
                    // アイコン
                    Image(systemName: "photo.on.rectangle")
                        .font(.system(size: 80))
                        .foregroundColor(.orange)
                    
                    Text("写真からQRコードを読み取り")
                        .font(.title2.bold())
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                    
                    Text("カメラロールから写真を選択して\nQRコードをスキャンできます")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                    
                    Spacer()
                    
                    // 選択ボタン
                    Button("写真を選択") {
                        showingImagePicker = true
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .tint(.orange)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("写真からスキャン")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $inputImage)
            }
            .onChange(of: inputImage) { newImage in
                if let image = newImage {
                    viewModel.scanQRFromImage(image)
                    dismiss()
                }
            }
        }
    }
}

// MARK: - QR Generator View
struct QRGeneratorView: View {
    @ObservedObject var viewModel: QRScannerViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var inputText = ""
    @State private var selectedType: QRGeneratorType = .text
    @State private var showingShareSheet = false
    
    enum QRGeneratorType: String, CaseIterable {
        case text = "テキスト"
        case url = "URL"
        case email = "メール"
        case phone = "電話番号"
        case wifi = "Wi-Fi"
        
        var icon: String {
            switch self {
            case .text: return "text.bubble"
            case .url: return "safari"
            case .email: return "envelope"
            case .phone: return "phone"
            case .wifi: return "wifi"
            }
        }
        
        var placeholder: String {
            switch self {
            case .text: return "テキストを入力..."
            case .url: return "https://example.com"
            case .email: return "example@email.com"
            case .phone: return "090-1234-5678"
            case .wifi: return "WIFI:T:WPA;S:ネットワーク名;P:パスワード;;"
            }
        }
        
        var color: Color {
            switch self {
            case .text: return .green
            case .url: return .blue
            case .email: return .orange
            case .phone: return .purple
            case .wifi: return .cyan
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                GlassmorphismBackground()
                
                ScrollView {
                    VStack(spacing: 30) {
                        // タイプ選択
                        GlassCard {
                            VStack(alignment: .leading, spacing: 15) {
                                Text("QRコードの種類")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 15) {
                                        ForEach(QRGeneratorType.allCases, id: \.self) { type in
                                            Button(action: {
                                                selectedType = type
                                                inputText = ""
                                            }) {
                                                VStack(spacing: 8) {
                                                    Image(systemName: type.icon)
                                                        .font(.title2)
                                                        .foregroundColor(
                                                            selectedType == type ? .white : type.color
                                                        )
                                                    
                                                    Text(type.rawValue)
                                                        .font(.caption.bold())
                                                        .foregroundColor(
                                                            selectedType == type ? .white : type.color
                                                        )
                                                }
                                                .frame(width: 70, height: 70)
                                                .background(
                                                    selectedType == type ?
                                                    type.color : type.color.opacity(0.1)
                                                )
                                                .cornerRadius(15)
                                                .animation(.spring(response: 0.3), value: selectedType)
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                        
                        // テキスト入力
                        GlassCard {
                            VStack(alignment: .leading, spacing: 15) {
                                Text("内容を入力")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                TextField(selectedType.placeholder, text: $inputText, axis: .vertical)
                                    .textFieldStyle(.roundedBorder)
                                    .lineLimit(3...6)
                            }
                        }
                        
                        // QRコード生成・表示
                        if !inputText.isEmpty {
                            GlassCard {
                                VStack(spacing: 20) {
                                    Text("生成されたQRコード")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    if let qrImage = viewModel.generateQRCode(from: formatText(inputText, for: selectedType)) {
                                        Image(uiImage: qrImage)
                                            .interpolation(.none)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 200, height: 200)
                                            .background(.white)
                                            .cornerRadius(15)
                                            .onTapGesture {
                                                viewModel.generatedQRCode = qrImage
                                                showingShareSheet = true
                                            }
                                        
                                        Text("タップして共有")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding()
                }
            }
            .navigationTitle("QRコード作成")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let qrImage = viewModel.generatedQRCode {
                    ShareSheet(items: [qrImage])
                }
            }
        }
    }
    
    private func formatText(_ text: String, for type: QRGeneratorType) -> String {
        switch type {
        case .url:
            if !text.hasPrefix("http://") && !text.hasPrefix("https://") {
                return "https://" + text
            }
            return text
        case .email:
            if !text.hasPrefix("mailto:") {
                return "mailto:" + text
            }
            return text
        case .phone:
            if !text.hasPrefix("tel:") {
                return "tel:" + text
            }
            return text
        default:
            return text
        }
    }
}

// MARK: - Helper Views
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - App Entry Point
@main
struct QRScannerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
    }
}
