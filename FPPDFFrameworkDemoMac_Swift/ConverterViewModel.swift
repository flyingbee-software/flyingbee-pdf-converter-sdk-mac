//
//  ConverterViewModel.swift
//  FPPDFFrameworkDemoMac_Swift
//
//  SwiftUI view model holding all conversion settings and driving the
//  FPPDFFramework SDK through the Objective-C++ bridge.
//
//  Created by James Wei on 9/4/26.
//  Copyright (c) 2026 Flyingbee Software. All rights reserved.
//

import SwiftUI
import CoreGraphics

// MARK: - Enums

/// Supported output formats (identical to the Objective-C demo)
enum OutputFormat: String, CaseIterable, Identifiable {
    case docx, pptx, xlsx, csv, txt, rtf, html, image, element

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .docx:    return "Word (*.docx)"
        case .pptx:    return "PowerPoint (*.pptx)"
        case .xlsx:    return "Excel (*.xlsx)"
        case .csv:     return "CSV (*.csv)"
        case .txt:     return "Text (*.txt)"
        case .rtf:     return "RTF (*.rtf)"
        case .html:    return "HTML (*.html)"
        case .image:   return "Image"
        case .element: return "Element (XML)"
        }
    }

    var iconName: String {
        self == .element ? "format_elements" : "format_\(rawValue)"
    }
}

/// Image formats for the "Image" output
enum ImageFormat: Int, CaseIterable, Identifiable {
    case jpeg = 0, png, bmp, gif, tiff, tga, jpeg2000

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .jpeg:     return "JPEG"
        case .png:      return "PNG"
        case .bmp:      return "BMP"
        case .gif:      return "GIF"
        case .tiff:     return "TIFF"
        case .tga:      return "TGA"
        case .jpeg2000: return "JPEG2000"
        }
    }

    var extensionName: String {
        switch self {
        case .jpeg:     return "jpeg"
        case .png:      return "png"
        case .bmp:      return "bmp"
        case .gif:      return "gif"
        case .tiff:     return "tiff"
        case .tga:      return "tga"
        case .jpeg2000: return "jp2"
        }
    }

    var iconName: String {
        switch self {
        case .jpeg:     return "format_jpeg"
        case .png:      return "format_png"
        case .bmp:      return "format_bmp"
        case .gif:      return "format_gif"
        case .tiff:     return "format_tiff"
        case .tga:      return "format_tga"
        case .jpeg2000: return "format_j2k"
        }
    }
}

/// Page range mode
enum PageRangeMode: Int, CaseIterable, Identifiable {
    case all = 0, first10, first3, first1, custom

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .all:     return "All Pages"
        case .first10: return "First 10"
        case .first3:  return "First 3"
        case .first1:  return "First 1"
        case .custom:  return "Customize:"
        }
    }
}

/// Multi-thread mode (0 = SDK auto/default)
enum ThreadMode: Int, CaseIterable, Identifiable {
    case auto = 0, two, five, ten, custom

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .auto:   return "1 Thread"
        case .two:    return "2"
        case .five:   return "5"
        case .ten:    return "10"
        case .custom: return "Customize:"
        }
    }

    var threadCount: Int? {
        switch self {
        case .auto:   return 0
        case .two:    return 2
        case .five:   return 5
        case .ten:    return 10
        case .custom: return nil
        }
    }
}

/// OCR language definition
struct OCRLanguage: Identifiable {
    let id: String       // Tesseract language code, e.g. "eng"
    let displayName: String
}

// MARK: - View Model

final class ConverterViewModel: ObservableObject {

    /// Shared instance, also used by the application delegate on launch/terminate.
    static let shared = ConverterViewModel()

    // MARK: - Shared value tables

    static let dpiValues = [36, 72, 144, 300, 600, 1200]
    static let qualityValues: [Float] = [0.3, 0.6, 0.83, 0.92, 1.0]
    static let qualityLabels = ["Low (0.3)", "Medium (0.6)", "Good (0.83)", "High (0.92)", "Best (1.0)"]
    static let wordDPIValues = [72, 144, 300, 600]
    static let ocrDPIValues = [72, 144, 200, 300, 600]

    /// Display order matches the Objective-C demo grid (row-major, 3 columns,
    /// with English intentionally placed at the end).
    static let ocrLanguages: [OCRLanguage] = [
        OCRLanguage(id: "fra",     displayName: "French"),
        OCRLanguage(id: "por",     displayName: "Portuguese"),
        OCRLanguage(id: "kor",     displayName: "Korean"),
        OCRLanguage(id: "deu",     displayName: "German"),
        OCRLanguage(id: "nld",     displayName: "Nederlands"),
        OCRLanguage(id: "jpn",     displayName: "Japanese"),
        OCRLanguage(id: "ita",     displayName: "Italian"),
        OCRLanguage(id: "swe",     displayName: "Swedish"),
        OCRLanguage(id: "chi_sim", displayName: "Simplified Chinese"),
        OCRLanguage(id: "spa",     displayName: "Spanish"),
        OCRLanguage(id: "pol",     displayName: "Polski"),
        OCRLanguage(id: "chi_tra", displayName: "Traditional Chinese"),
        OCRLanguage(id: "rus",     displayName: "Russian"),
        OCRLanguage(id: "tur",     displayName: "Türkiye"),
        OCRLanguage(id: "ara",     displayName: "Arabic"),
        OCRLanguage(id: "ukr",     displayName: "Ukrainian"),
        OCRLanguage(id: "ind",     displayName: "Indonesian"),
        OCRLanguage(id: "ces",     displayName: "Czech"),
        OCRLanguage(id: "eng",     displayName: "English"),
        OCRLanguage(id: "vie",     displayName: "Vietnamese"),
    ]

    /// Output formats whose result is a folder rather than a single file
    private static let folderFormats: Set<String> = ["csv", "htm", "html", "element", "elements",
                                                     "image", "images", "jpg", "jpeg", "png",
                                                     "bmp", "gif", "tif", "tiff", "tga", "jp2"]

    // MARK: - Source / output

    @Published var sourceURLs: [URL] = []
    @Published var sourcePathText: String = ""
    @Published var pdfPassword: String = ""
    @Published var outputDirectoryURL: URL?
    @Published var outputPathText: String = ""

    // MARK: - Format

    @Published var outputFormat: OutputFormat = .docx
    @Published var imageFormat: ImageFormat = .png

    // MARK: - General settings

    @Published var openAfterConversion: Bool = true
    @Published var pageRangeMode: PageRangeMode = .all
    @Published var customPageRange: String = ""
    @Published var threadMode: ThreadMode = .auto
    @Published var customThreadCount: String = ""
    @Published var imageDPI: Int = 300
    @Published var imageQualityIndex: Int = 3

    // MARK: - Word (DOCX) settings

    @Published var wordTrimBlankSpace: Bool = true
    @Published var wordMergeParagraphs: Bool = false
    @Published var wordShapeToImage: Bool = true
    @Published var wordMergeIntersectImages: Bool = true
    @Published var wordImageDPI: Int = 300
    @Published var wordOutlineType: Int = 1

    // MARK: - Excel (XLSX/CSV) settings

    @Published var excelAllInOneSheet: Bool = false
    @Published var excelRecognizeNumber: Bool = true
    @Published var excelAllInOneStyle: Int = 0       // 0 = append rows, 1 = append columns
    @Published var excelFormatOption: Int = 0
    @Published var excelThousandSeparator: Int = 0
    @Published var excelOverlapText: Int = 0
    @Published var csvPackageZip: Bool = false

    // MARK: - HTML settings

    @Published var htmlLayoutMode: Int = 0
    @Published var htmlMergeResource: Int = 2
    @Published var htmlNavigationBar: Int = 1
    @Published var htmlTextFlowParagraph: Int = 0
    @Published var htmlPackageZip: Bool = false

    // MARK: - Image output settings

    @Published var imageOutputDPI: Int = 300
    @Published var imageOutputQualityIndex: Int = 3
    @Published var imagePackageZip: Bool = false
    @Published var imageAntiAlias: Bool = true

    // MARK: - Element output settings

    @Published var elementQualityIndex: Int = 3
    @Published var elementPackageZip: Bool = false

    // MARK: - OCR settings

    @Published var ocrEnabled: Bool = false
    @Published var ocrImageScan: Bool = false
    @Published var ocrDPI: Int = 300
    @Published var ocrLanguageText: String = ""
    @Published var ocrSelectedLanguages: Set<String> = []

    // MARK: - Status & license

    @Published var statusMessage: String = ""
    @Published var isConverting: Bool = false
    @Published var progressValue: Double = 0
    @Published var licenseOrganization: String = ""
    @Published var licenseExpiredDate: String = ""
    @Published var licenseExpired: Bool = false

    // MARK: - Private

    private let converter = FPPDFConverterBridge()
    private var pendingURLs: [URL] = []
    private var restoredURLs: [URL] = []  // security-scoped URLs that must be released at quit
    private let defaults = UserDefaults.standard

    // MARK: - Init / persistence

    init() {
        loadSettings()
        loadLicenseInfo()
    }

    /// Loads all persisted preferences (same keys as the Objective-C demo).
    func loadSettings() {
        sourcePathText = defaults.string(forKey: "sourePath") ?? ""
        pdfPassword = defaults.string(forKey: "sourePassword") ?? ""
        if !sourcePathText.isEmpty {
            sourceURLs = [URL(fileURLWithPath: sourcePathText)]
        }

        if let raw = defaults.string(forKey: "outputFormat"),
           let format = OutputFormat(rawValue: raw) {
            outputFormat = format
        }
        imageFormat = ImageFormat(rawValue: defaults.integer(forKey: "imageFormat")) ?? .png

        openAfterConversion = defaults.object(forKey: "settings_openAfterConversion") == nil
            ? true
            : defaults.bool(forKey: "settings_openAfterConversion")

        pageRangeMode = PageRangeMode(rawValue: defaults.integer(forKey: "settings_pageRangeSegment")) ?? .all
        customPageRange = defaults.string(forKey: "settings_pageRange") ?? ""
        if customPageRange.isEmpty { customPageRange = "1" }

        threadMode = ThreadMode(rawValue: defaults.integer(forKey: "settings_multiThreadSegment")) ?? .auto
        customThreadCount = defaults.string(forKey: "settings_multiThread") ?? ""
        if customThreadCount.isEmpty { customThreadCount = "3" }

        let savedDPI = defaults.integer(forKey: "settings_imageDPI")
        imageDPI = savedDPI == 0 ? 300 : savedDPI
        let savedQuality = defaults.object(forKey: "settings_imageQuality") as? Int
        imageQualityIndex = savedQuality ?? 3

        wordTrimBlankSpace = defaults.object(forKey: "docx_trimBlankSpace") == nil ? true : defaults.bool(forKey: "docx_trimBlankSpace")
        wordMergeParagraphs = defaults.bool(forKey: "docx_mergeParagraph")
        wordShapeToImage = defaults.object(forKey: "docx_enableShapToImage") == nil ? true : defaults.bool(forKey: "docx_enableShapToImage")
        wordMergeIntersectImages = defaults.object(forKey: "docx_enableMergeImages") == nil ? true : defaults.bool(forKey: "docx_enableMergeImages")
        let savedWordDPI = defaults.integer(forKey: "docx_imageDPI")
        wordImageDPI = savedWordDPI == 0 ? 300 : savedWordDPI
        wordOutlineType = defaults.object(forKey: "docx_outline") == nil ? 1 : defaults.integer(forKey: "docx_outline")

        excelAllInOneSheet = defaults.bool(forKey: "xlsx_allInOneSheet")
        excelRecognizeNumber = defaults.object(forKey: "xlsx_recognizeNumber") == nil ? true : defaults.bool(forKey: "xlsx_recognizeNumber")
        excelAllInOneStyle = defaults.integer(forKey: "xlsx_AIOStyle")
        excelFormatOption = defaults.integer(forKey: "xlsx_outputFormat")
        excelThousandSeparator = defaults.integer(forKey: "xlsx_ThousandSeparator")
        excelOverlapText = defaults.integer(forKey: "xlsx_OverlapText")
        csvPackageZip = defaults.bool(forKey: "xlsx_csv_isPackageZip")

        htmlLayoutMode = defaults.integer(forKey: "html_layoutMode")
        htmlMergeResource = defaults.object(forKey: "html_mergeResource") == nil ? 2 : defaults.integer(forKey: "html_mergeResource")
        htmlNavigationBar = defaults.object(forKey: "html_navigationBar") == nil ? 1 : defaults.integer(forKey: "html_navigationBar")
        htmlTextFlowParagraph = defaults.integer(forKey: "html_textFlowParagraph")
        htmlPackageZip = defaults.bool(forKey: "html_isPackageZip")

        let savedImageDPI = defaults.integer(forKey: "image_imageDPI")
        imageOutputDPI = savedImageDPI == 0 ? 300 : savedImageDPI
        imageOutputQualityIndex = defaults.object(forKey: "image_imageQuality") as? Int ?? 3
        imagePackageZip = defaults.bool(forKey: "image_isPackageZip")
        imageAntiAlias = defaults.object(forKey: "image_isAntiAlias") == nil ? true : defaults.bool(forKey: "image_isAntiAlias")

        elementQualityIndex = defaults.object(forKey: "element_imageQuality") as? Int ?? 3
        elementPackageZip = defaults.bool(forKey: "element_isPackageZip")

        ocrEnabled = defaults.bool(forKey: "settings_ocr_isEnableOCR")
        ocrImageScan = defaults.bool(forKey: "settings_ocr_isEnableImageScan")
        let savedOCRDPI = defaults.integer(forKey: "settings_ocr_imageDPI")
        ocrDPI = savedOCRDPI == 0 ? 300 : savedOCRDPI
        ocrLanguageText = defaults.string(forKey: "settings_ocr_languages") ?? ""
        ocrSelectedLanguages = Set(ocrLanguageText.split(separator: "+").map(String.init))

        // Show the effective output folder even before the user picks one, so
        // the field always matches where files will actually be written.
        // A persisted bookmark (restored later by `restoreOutputDirectory()`)
        // overrides this default.
        if outputPathText.isEmpty {
            outputPathText = Self.documentsDirectory()?.path ?? ""
        }
    }

    /// Persists every user-facing setting.
    func saveSettings() {
        defaults.set(sourcePathText, forKey: "sourePath")
        defaults.set(pdfPassword, forKey: "sourePassword")
        defaults.set(outputFormat.rawValue, forKey: "outputFormat")
        defaults.set(imageFormat.rawValue, forKey: "imageFormat")

        defaults.set(openAfterConversion, forKey: "settings_openAfterConversion")

        defaults.set(pageRangeMode.rawValue, forKey: "settings_pageRangeSegment")
        defaults.set(customPageRange, forKey: "settings_pageRange")

        defaults.set(threadMode.rawValue, forKey: "settings_multiThreadSegment")
        defaults.set(customThreadCount, forKey: "settings_multiThread")

        defaults.set(imageDPI, forKey: "settings_imageDPI")
        defaults.set(imageQualityIndex, forKey: "settings_imageQuality")

        defaults.set(wordTrimBlankSpace, forKey: "docx_trimBlankSpace")
        defaults.set(wordMergeParagraphs, forKey: "docx_mergeParagraph")
        defaults.set(wordShapeToImage, forKey: "docx_enableShapToImage")
        defaults.set(wordMergeIntersectImages, forKey: "docx_enableMergeImages")
        defaults.set(wordImageDPI, forKey: "docx_imageDPI")
        defaults.set(wordOutlineType, forKey: "docx_outline")

        defaults.set(excelAllInOneSheet, forKey: "xlsx_allInOneSheet")
        defaults.set(excelRecognizeNumber, forKey: "xlsx_recognizeNumber")
        defaults.set(excelAllInOneStyle, forKey: "xlsx_AIOStyle")
        defaults.set(excelFormatOption, forKey: "xlsx_outputFormat")
        defaults.set(excelThousandSeparator, forKey: "xlsx_ThousandSeparator")
        defaults.set(excelOverlapText, forKey: "xlsx_OverlapText")
        defaults.set(csvPackageZip, forKey: "xlsx_csv_isPackageZip")

        defaults.set(htmlLayoutMode, forKey: "html_layoutMode")
        defaults.set(htmlMergeResource, forKey: "html_mergeResource")
        defaults.set(htmlNavigationBar, forKey: "html_navigationBar")
        defaults.set(htmlTextFlowParagraph, forKey: "html_textFlowParagraph")
        defaults.set(htmlPackageZip, forKey: "html_isPackageZip")

        defaults.set(imageOutputDPI, forKey: "image_imageDPI")
        defaults.set(imageOutputQualityIndex, forKey: "image_imageQuality")
        defaults.set(imagePackageZip, forKey: "image_isPackageZip")
        defaults.set(imageAntiAlias, forKey: "image_isAntiAlias")

        defaults.set(elementQualityIndex, forKey: "element_imageQuality")
        defaults.set(elementPackageZip, forKey: "element_isPackageZip")

        defaults.set(ocrEnabled, forKey: "settings_ocr_isEnableOCR")
        defaults.set(ocrImageScan, forKey: "settings_ocr_isEnableImageScan")
        defaults.set(ocrDPI, forKey: "settings_ocr_imageDPI")
        defaults.set(ocrLanguageText, forKey: "settings_ocr_languages")
    }

    /// Releases all security-scoped resources. Called when the app terminates.
    func releaseSecurityScopedResources() {
        outputDirectoryURL?.stopAccessingSecurityScopedResource()
        restoredURLs.forEach { $0.stopAccessingSecurityScopedResource() }
        restoredURLs.removeAll()
    }

    // MARK: - License

    func loadLicenseInfo() {
        licenseOrganization = FPPDFConverterBridge.sdkLicenseOrganization()
        licenseExpiredDate = FPPDFConverterBridge.sdkLicenseExpiredDate()
        licenseExpired = FPPDFConverterBridge.isSDKLicenseAuthExpiredDate()
    }

    var licenseText: String {
        var text = "🔐 License to \(licenseOrganization)\n🕗 Expiration date: \(licenseExpiredDate)"
        if licenseExpired { text += "\n❌ License Expired" }
        return text
    }

    // MARK: - Restoring persisted locations

    /// Restores the previously saved output directory from a security-scoped bookmark.
    func restoreOutputDirectory() {
        guard let bookmark = defaults.data(forKey: "OutputDirectoryBookmark") else { return }

        var isStale = false
        do {
            let url = try URL(resolvingBookmarkData: bookmark,
                              options: .withSecurityScope,
                              relativeTo: nil,
                              bookmarkDataIsStale: &isStale)
            if isStale {
                statusMessage = "⚠️ The output directory bookmark has expired (files have been moved or deleted)"
                defaults.removeObject(forKey: "OutputDirectoryBookmark")
                return
            }
            if url.startAccessingSecurityScopedResource() {
                outputDirectoryURL = url
                outputPathText = url.path
            } else {
                statusMessage = "❌ Failed to restore output directory"
            }
        } catch {
            statusMessage = "❌ Unable to resolve output directory bookmark: \(error.localizedDescription)"
        }
    }

    /// Restores previously selected PDF files from security-scoped bookmarks.
    func restoreBookmarkedFiles() {
        guard let bookmarks = defaults.array(forKey: "SavedPDFBookmarks") as? [Data] else { return }

        var urls: [URL] = []
        for bookmark in bookmarks {
            var isStale = false
            do {
                let url = try URL(resolvingBookmarkData: bookmark,
                                  options: .withSecurityScope,
                                  relativeTo: nil,
                                  bookmarkDataIsStale: &isStale)
                if url.startAccessingSecurityScopedResource() {
                    urls.append(url)
                }
            } catch {
                NSLog("Failed to resolve bookmark: \(error)")
            }
        }

        guard !urls.isEmpty else { return }
        restoredURLs = urls
        sourceURLs = urls
        sourcePathText = urls.first?.path ?? ""
        statusMessage = "The \(urls.count) files have been restored"
    }

    // MARK: - File selection

    /// Shows an open panel to pick one or more PDF files.
    func selectPDFFiles() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = true
        panel.allowedContentTypes = [.pdf]

        guard panel.runModal() == .OK else { return }

        let urls = panel.urls
        sourceURLs = urls
        sourcePathText = urls.first?.path ?? ""

        // Persist security-scoped bookmarks
        var bookmarks: [Data] = []
        for url in urls {
            do {
                let bookmark = try url.bookmarkData(options: .withSecurityScope,
                                                    includingResourceValuesForKeys: nil,
                                                    relativeTo: nil)
                bookmarks.append(bookmark)
            } catch {
                NSLog("Failed to create bookmark for \(url): \(error)")
            }
        }
        defaults.set(bookmarks, forKey: "SavedPDFBookmarks")

        if urls.count > 1 {
            statusMessage = "You have selected \(urls.count) PDF files, you can start now!"
        } else if let first = urls.first {
            if let document = CGPDFDocument(first as CFURL) {
                statusMessage = "You have selected \(urls.count) PDF files, with a total of \(document.numberOfPages) pages"
            } else {
                statusMessage = "Unable to open the selected PDF file"
            }
        }
        saveSettings()
    }

    /// Shows an open panel to pick the output directory.
    func selectOutputDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true

        guard panel.runModal() == .OK, let url = panel.url else { return }

        outputDirectoryURL?.stopAccessingSecurityScopedResource()
        outputPathText = url.path

        do {
            let bookmark = try url.bookmarkData(options: .withSecurityScope,
                                                includingResourceValuesForKeys: nil,
                                                relativeTo: nil)
            defaults.set(bookmark, forKey: "OutputDirectoryBookmark")
            if url.startAccessingSecurityScopedResource() {
                outputDirectoryURL = url
            }
        } catch {
            statusMessage = "❌ Failed to create directory bookmark: \(error.localizedDescription)"
        }
    }

    // MARK: - Conversion

    /// Starts converting every selected PDF file, one after another.
    func startConversion() {
        saveSettings()

        guard !sourceURLs.isEmpty else {
            statusMessage = "⚠️ Please select at least one PDF file first."
            return
        }
        guard !isConverting, !converter.isConverting else {
            NSSound.beep()
            return
        }

        isConverting = true
        progressValue = 0
        statusMessage = ""
        pendingURLs = sourceURLs
        convertNext()
    }

    /// Cancels the running conversion.
    func stopConversion() {
        _ = converter.cancelConversion()
        pendingURLs.removeAll()
        isConverting = false
        statusMessage = "🛑 Conversion cancelled."
    }

    /// Converts the next file in the queue.
    private func convertNext() {
        guard !pendingURLs.isEmpty else {
            isConverting = false
            return
        }
        convertPDF(at: pendingURLs.removeLast())
    }

    /// Builds the conversion options and starts a single PDF conversion.
    private func convertPDF(at url: URL) {
        let pdfPath = url.path

        var numberOfPages = 1
        if let document = CGPDFDocument(url as CFURL) {
            numberOfPages = document.numberOfPages
        }

        // Page indexes are 1-based
        let pageIndexes = buildPageIndexes(pageCount: numberOfPages)

        // Thread count
        var threadCount = threadMode.threadCount ?? Int(customThreadCount) ?? 3
        threadCount = min(max(threadCount, 0), 20)

        // Destination
        let destDocType: String = (outputFormat == .image) ? imageFormat.extensionName : outputFormat.rawValue

        guard let outputDir = resolvedOutputDirectory() else {
            isConverting = false
            statusMessage = "❌ Unable to obtain the output directory."
            return
        }

        // File name only — the Objective-C demo uses `[pdfPath lastPathComponent]
        // stringByDeletingPathExtension`. Using the whole path here would append
        // an absolute path onto the output directory and produce a destination
        // outside the Documents folder.
        let baseName = URL(fileURLWithPath: pdfPath).deletingPathExtension().lastPathComponent
        let filename = Self.folderFormats.contains(destDocType)
            ? "\(baseName)_\(destDocType)"
            : "\(baseName).\(destDocType)"
        let destURL = outputDir.appendingPathComponent(filename)
        NSLog("destDocPath: \(destURL.path)")

        try? FileManager.default.removeItem(at: destURL)

        let options = buildOptions(threadCount: threadCount)
        let startDate = Date()

        converter.convertPDF(atPath: pdfPath,
                             password: pdfPassword,
                             pageIndexes: pageIndexes,
                             outputFormat: destDocType,
                             destPath: destURL.path,
                             options: options,
                             isInBackground: true,
                             didStartHandler: { [weak self] success, error in
            guard let self = self else { return }
            NSLog("Started: \(success), errorInfo: \(error ?? "nil")")
            DispatchQueue.main.async {
                self.statusMessage = "Progress: Converting to \(destDocType), page 1..."
            }
        },
                             progressHandler: { [weak self] currentPage, total, success, error in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.statusMessage = "Progress: Converting to \(destDocType), \(currentPage) of \(total) pages..."
                self.progressValue = total > 0 ? Double(currentPage) / Double(total) : 0
            }
        },
                             willSaveHandler: { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.statusMessage = "Progress: Saving as \(destDocType)..."
            }
        },
                             completionHandler: { [weak self] success, error in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.handleCompletion(success: success,
                                      error: error,
                                      destURL: destURL,
                                      destDocType: destDocType,
                                      startDate: startDate)
            }
        })
    }

    /// Handles the end of a single file conversion and continues the queue.
    private func handleCompletion(success: Bool,
                                  error: String?,
                                  destURL: URL,
                                  destDocType: String,
                                  startDate: Date) {
        if success {
            let elapsed = Date().timeIntervalSince(startDate)
            if openAfterConversion {
                statusMessage = String(format: "✅ Conversion successful! The output file will be opened, taking %0.0f seconds!", elapsed)
                NSWorkspace.shared.open(destURL)
            } else {
                statusMessage = String(format: "✅ Conversion successful! The output file is stored in the output folder, taking %0.0f seconds!", elapsed)
            }
        } else {
            statusMessage = "❌ Conversion failed: \(error ?? "Unknown error")"
        }

        progressValue = 0
        convertNext()
    }

    /// The app's own Documents folder. When the app runs inside its sandbox
    /// this resolves to the container's `.../Data/Documents`; otherwise it is
    /// the user's `~/Documents`. This is the default place converted files go
    /// to until the user picks another folder with "Select...".
    private static func documentsDirectory() -> URL? {
        let fm = FileManager.default
        guard let url = fm.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        // The folder normally exists, but create it so the path is always usable.
        if !fm.fileExists(atPath: url.path) {
            try? fm.createDirectory(at: url, withIntermediateDirectories: true)
        }
        return url
    }

    /// Returns the user-selected output directory, falling back to Documents.
    private func resolvedOutputDirectory() -> URL? {
        if let dir = outputDirectoryURL { return dir }
        return Self.documentsDirectory()
    }

    /// Builds the SDK option object from the current settings.
    private func buildOptions(threadCount: Int) -> FPPDFConversionOptions {
        let options = FPPDFConversionOptions()
        options.isParserAnnots = 1
        options.threadMax = Int32(threadCount)
        options.imageQuality = Self.qualityValues[imageQualityIndex]
        options.imageDPI = Int32(imageDPI)

        // Word (DOCX)
        options.wordOptions.outlineType = wordOutlineType
        options.wordOptions.isTrimmingBlankSpaceCharacters = wordTrimBlankSpace
        options.wordOptions.isMergeParagraphs = wordMergeParagraphs
        options.wordOptions.enableShapeToImage = wordShapeToImage
        options.wordOptions.enableMergeIntersectImages = wordMergeIntersectImages
        // The Word tab owns the global image DPI in the original demo
        options.imageDPI = Int32(wordImageDPI)

        // Excel (XLSX/CSV)
        options.excelOptions.excelFormatOption = excelFormatOption
        options.excelOptions.thousandSeparator = excelThousandSeparator
        options.excelOptions.allInOneSheet = excelAllInOneSheet
        options.excelOptions.allInOneSheetAddToRow = (excelAllInOneStyle == 0)
        options.excelOptions.overlapText = excelOverlapText
        options.excelOptions.recognizeNumber = excelRecognizeNumber
        options.excelOptions.isCSVPackageZip = csvPackageZip

        // Image output
        options.imageOptions.imageFormat = imageFormat.rawValue
        options.imageOptions.imageQuality = Self.qualityValues[imageOutputQualityIndex]
        options.imageOptions.imageDPI = Int32(imageOutputDPI)
        options.imageOptions.isPackageZip = imagePackageZip
        options.imageOptions.isAntiAlias = imageAntiAlias

        // Element output
        options.elementOptions.imageQuality = Self.qualityValues[elementQualityIndex]
        options.elementOptions.isPackageZip = elementPackageZip

        // HTML output
        options.wordOptions.htmlLayoutMode = htmlLayoutMode
        options.wordOptions.htmlMergeResource = htmlMergeResource
        options.wordOptions.htmlTextFlowParagraph = htmlTextFlowParagraph
        options.wordOptions.htmlNavigationBar = htmlNavigationBar
        options.wordOptions.htmlPackage = htmlPackageZip ? 1 : 0

        // OCR
        options.isEnableOCR = ocrEnabled
        options.ocrOptions.language = ocrLanguageText.isEmpty ? "chi_sim+eng" : ocrLanguageText
        options.ocrOptions.engineMode = 1 // FPPDFOCREngineMode_LSTM_ONLY
        options.ocrOptions.resizeDPI = UInt32(ocrDPI)
        options.ocrOptions.minConfidence = 10.0
        options.ocrOptions.isEnableImageScan = ocrImageScan

        return options
    }

    /// Builds the 1-based page index array from the selected page range mode.
    func buildPageIndexes(pageCount: Int) -> [NSNumber] {
        var indexes: [NSNumber] = []

        switch pageRangeMode {
        case .all:
            for i in 1...max(pageCount, 1) { indexes.append(NSNumber(value: i)) }
        case .first10:
            for i in 1...10 { indexes.append(NSNumber(value: i)) }
        case .first3:
            for i in 1...3 { indexes.append(NSNumber(value: i)) }
        case .first1:
            indexes = [NSNumber(value: 1)]
        case .custom:
            let text = customPageRange
            if text.isEmpty {
                indexes = [NSNumber(value: 1)]
                break
            }
            for part in text.components(separatedBy: ",") {
                let piece = part.trimmingCharacters(in: .whitespaces)
                if piece.contains("-") {
                    let bounds = piece.components(separatedBy: "-")
                    guard bounds.count == 2,
                          let first = Int(bounds[0].trimmingCharacters(in: .whitespaces)),
                          let last = Int(bounds[1].trimmingCharacters(in: .whitespaces)) else { continue }

                    if last > first {
                        for value in first...last where value > 0 && value <= pageCount {
                            indexes.append(NSNumber(value: value))
                        }
                    } else if first > last {
                        var value = first
                        while value >= last {
                            if value > 0 && value <= pageCount {
                                indexes.append(NSNumber(value: value))
                            }
                            value -= 1
                        }
                    }
                } else if let value = Int(piece), value > 0, value <= pageCount {
                    indexes.append(NSNumber(value: value))
                }
            }
            if indexes.isEmpty { indexes = [NSNumber(value: 1)] }
        }

        return indexes
    }

    // MARK: - OCR language handling

    /// Toggles an OCR language and updates the language string.
    func toggleOCRLanguage(_ code: String, isOn: Bool) {
        if isOn {
            ocrSelectedLanguages.insert(code)
        } else {
            ocrSelectedLanguages.remove(code)
        }

        // Preserve the visual order of the language list
        let ordered = Self.ocrLanguages.map { $0.id }.filter { ocrSelectedLanguages.contains($0) }
        ocrLanguageText = ordered.joined(separator: "+")
        defaults.set(ocrLanguageText, forKey: "settings_ocr_languages")
    }

    // MARK: - Finder actions

    /// Reveals the source PDF in Finder.
    func revealSourceFile() {
        let path = sourcePathText
        guard !path.isEmpty else { return }
        NSWorkspace.shared.selectFile(path,
                                      inFileViewerRootedAtPath: (path as NSString).deletingLastPathComponent)
    }

    /// Reveals the last converted file in Finder.
    func revealConvertedFile() {
        let path = converter.destPath
        guard !path.isEmpty, FileManager.default.fileExists(atPath: path) else {
            statusMessage = "The converted file does not exist yet."
            return
        }
        NSWorkspace.shared.selectFile(path,
                                      inFileViewerRootedAtPath: (path as NSString).deletingLastPathComponent)
    }

    /// Opens the SDK log folder in Finder.
    func revealLogFolder() {
        let logPath = FPPDFConverterBridge.debugLogPath()
        NSWorkspace.shared.selectFile(logPath,
                                      inFileViewerRootedAtPath: (logPath as NSString).deletingLastPathComponent)
    }

    /// Opens the output folder in Finder.
    func openOutputFolder() {
        guard let url = resolvedOutputDirectory() else { return }
        NSWorkspace.shared.open(url)
    }
}


// MARK: - Deferred bindings
//
// On macOS the AppKit-backed controls used by SwiftUI (segmented pickers,
// check boxes, ...) may deliver their action while SwiftUI is still updating
// views. Writing to an @Published property at that exact moment publishes a
// change from inside the update pass, which logs:
//     "Publishing changes from within view updates is not allowed,
//      this will cause undefined behavior."
// These bindings apply the write on the next turn of the main run loop, when
// the update has finished. Text fields keep their plain bindings so typing is
// never deferred.
extension ConverterViewModel {

    /// A binding that reads a property normally but writes it asynchronously.
    ///
    /// - Parameter keyPath: the property that is read and written.
    func deferred<Value>(_ keyPath: ReferenceWritableKeyPath<ConverterViewModel, Value>) -> Binding<Value> {
        Binding(
            get: { self[keyPath: keyPath] },
            set: { [weak self] value in
                DispatchQueue.main.async { self?[keyPath: keyPath] = value }
            }
        )
    }
}
