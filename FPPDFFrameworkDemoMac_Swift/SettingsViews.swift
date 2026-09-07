//
//  SettingsViews.swift
//  FPPDFFrameworkDemoMac_Swift
//
//  Per-format setting panes, mirroring the tab view of the Objective-C demo.
//
//  Each pane lays its rows out in a SwiftUI `Grid`: the label column sizes
//  itself to the widest label of the pane, so rows stay aligned and localized
//  labels are never truncated. Controls use flexible (min/max) widths instead
//  of fixed ones so longer localized text can grow the control.
//
//  Created by James Wei on 9/4/26.
//  Copyright (c) 2026 Flyingbee Software. All rights reserved.
//

import SwiftUI

// MARK: - Pane styling

/// Draws the rounded (弧形) border around a settings pane, mirroring the
/// group box used by the Objective-C demo.
struct SettingsPaneModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(10)
            // NOTE: do NOT use `maxHeight: .infinity` here — it lets the pane
            // expand without bound and inflates the window's ideal height far
            // beyond the controls it contains (the window then can't shrink).
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(nsColor: .textBackgroundColor).opacity(0.7))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
            )
    }
}

extension View {
    /// Wraps the receiver in an arc-ed bordered settings pane.
    func settingsPane() -> some View { modifier(SettingsPaneModifier()) }
}

// MARK: - Shared helpers

/// One "label + controls" row of a settings pane. Must be placed directly
/// inside a `Grid` so the label column aligns across all rows of the pane.
private struct SettingRow<Content: View>: View {
    let title: String
    let help: String?
    @ViewBuilder var content: Content

    init(_ title: String, help: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.help = help
        self.content = content()
    }

    var body: some View {
        GridRow {
            Text(title)
                .help(help ?? "")

            HStack(spacing: 12) {
                content
                Spacer(minLength: 0)
            }
            .help(help ?? "")
        }
    }
}

/// The standard grid container used by every settings pane.
private struct SettingsGrid<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 10, verticalSpacing: 10) {
            content
        }
    }
}

// MARK: - General

struct GeneralSettingsView: View {
    @EnvironmentObject private var vm: ConverterViewModel

    var body: some View {
        VStack(spacing: 10) {
            SettingsGrid {
                SettingRow("Image DPI", help: "Default DPI used for embedded images") {
                    Picker("", selection: vm.deferred(\.imageDPI)) {
                        ForEach(ConverterViewModel.dpiValues, id: \.self) { Text("\($0) DPI").tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 440)
                }

                SettingRow("Image quality", help: "Compression quality of embedded images") {
                    Picker("", selection: vm.deferred(\.imageQualityIndex)) {
                        ForEach(Array(ConverterViewModel.qualityLabels.enumerated()), id: \.offset) { index, label in
                            Text(label)
                                .frame(minWidth: 200, alignment: .leading)
                                .tag(index)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }

            Spacer()
        }
    }
}

// MARK: - Word (DOCX)

struct WordSettingsView: View {
    @EnvironmentObject private var vm: ConverterViewModel

    private let outlineModes = ["None", "PDF Outline", "Detect Outline"]

    var body: some View {
        VStack(spacing: 10) {
            SettingsGrid {
                SettingRow("Layout", help: "Trim redundant blank spaces and merge broken paragraphs") {
                    Toggle("Trim blank spaces", isOn: vm.deferred(\.wordTrimBlankSpace)).toggleStyle(.checkbox)
                    Toggle("Merge paragraphs", isOn: vm.deferred(\.wordMergeParagraphs)).toggleStyle(.checkbox)
                }

                SettingRow("Graphics", help: "Convert vector shapes to images and merge overlapping images") {
                    Toggle("Shapes to image", isOn: vm.deferred(\.wordShapeToImage)).toggleStyle(.checkbox)
                    Toggle("Merge intersect images", isOn: vm.deferred(\.wordMergeIntersectImages)).toggleStyle(.checkbox)
                }

                SettingRow("Image DPI", help: "DPI of the images written into the DOCX file") {
                    Picker("", selection: vm.deferred(\.wordImageDPI)) {
                        ForEach(ConverterViewModel.wordDPIValues, id: \.self) { Text("\($0) DPI").tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 360)
                }

                SettingRow("Outline", help: "How the document outline (bookmarks) is generated") {
                    Picker("", selection: vm.deferred(\.wordOutlineType)) {
                        ForEach(Array(outlineModes.enumerated()), id: \.offset) { index, title in
                            Text(title)
                                .frame(minWidth: 180, alignment: .leading)
                                .tag(index)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }

            Spacer()
        }
    }
}

// MARK: - Excel (XLSX / CSV)

struct ExcelSettingsView: View {
    @EnvironmentObject private var vm: ConverterViewModel

    private let formatOptions = ["Keep original formatting", "Retain data structure", "Special version"]
    private let separators = ["Auto", "Comma", "Dot", "Blank + comma", "Apostrophe + comma"]
    private let overlapModes = ["Auto", "Merge", "Split"]
    private let sheetStyles = ["Append to rows", "Append to columns"]

    var body: some View {
        VStack(spacing: 10) {
            SettingsGrid {
                SettingRow("All in one sheet", help: "Put every PDF page into a single worksheet") {
                    Toggle("", isOn: vm.deferred(\.excelAllInOneSheet)).toggleStyle(.checkbox).labelsHidden()

                    Picker("", selection: vm.deferred(\.excelAllInOneStyle)) {
                        ForEach(Array(sheetStyles.enumerated()), id: \.offset) { index, title in
                            Text(title)
                                .frame(minWidth: 180, alignment: .leading)
                                .tag(index)
                        }
                    }
                    .pickerStyle(.menu)
                    .disabled(!vm.excelAllInOneSheet)
                }

                SettingRow("Recognize numbers", help: "Detect numeric cells and convert them to real numbers") {
                    Toggle("", isOn: vm.deferred(\.excelRecognizeNumber)).toggleStyle(.checkbox).labelsHidden()
                }

                SettingRow("Output format") {
                    Picker("", selection: vm.deferred(\.excelFormatOption)) {
                        ForEach(Array(formatOptions.enumerated()), id: \.offset) { index, title in
                            Text(title)
                                .frame(minWidth: 220, alignment: .leading)
                                .tag(index)
                        }
                    }
                    .pickerStyle(.menu)
                }

                SettingRow("Thousand separator") {
                    Picker("", selection: vm.deferred(\.excelThousandSeparator)) {
                        ForEach(Array(separators.enumerated()), id: \.offset) { index, title in
                            Text(title)
                                .frame(minWidth: 220, alignment: .leading)
                                .tag(index)
                        }
                    }
                    .pickerStyle(.menu)
                }

                SettingRow("Overlap text") {
                    Picker("", selection: vm.deferred(\.excelOverlapText)) {
                        ForEach(Array(overlapModes.enumerated()), id: \.offset) { index, title in
                            Text(title)
                                .frame(minWidth: 160, alignment: .leading)
                                .tag(index)
                        }
                    }
                    .pickerStyle(.menu)
                }

                SettingRow("CSV", help: "Package CSV output as a ZIP archive") {
                    Toggle("Package as ZIP", isOn: vm.deferred(\.csvPackageZip)).toggleStyle(.checkbox)
                }
            }

            Spacer()
        }
    }
}

// MARK: - HTML

struct HTMLSettingsView: View {
    @EnvironmentObject private var vm: ConverterViewModel

    private let layoutModes = ["Page view", "Text flow view"]
    private let mergeResources = ["None", "CSS + JS", "CSS + JS + small images", "CSS + JS + all images"]
    private let navigationBars = ["None", "PDF viewer"]
    private let paragraphs = ["Blank line", "First line indent"]

    var body: some View {
        VStack(spacing: 10) {
            SettingsGrid {
                SettingRow("Layout mode") {
                    Picker("", selection: vm.deferred(\.htmlLayoutMode)) {
                        ForEach(Array(layoutModes.enumerated()), id: \.offset) { index, title in
                            Text(title)
                                .frame(minWidth: 240, alignment: .leading)
                                .tag(index)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 300)
                }

                SettingRow("Merge resources") {
                    Picker("", selection: vm.deferred(\.htmlMergeResource)) {
                        ForEach(Array(mergeResources.enumerated()), id: \.offset) { index, title in
                            Text(title)
                                .frame(minWidth: 240, alignment: .leading)
                                .tag(index)
                        }
                    }
                    .pickerStyle(.menu)
                }

                SettingRow("Navigation bar") {
                    Picker("", selection: vm.deferred(\.htmlNavigationBar)) {
                        ForEach(Array(navigationBars.enumerated()), id: \.offset) { index, title in
                            Text(title)
                                .frame(minWidth: 160, alignment: .leading)
                                .tag(index)
                        }
                    }
                    .pickerStyle(.menu)
                }

                SettingRow("Paragraph", help: "Only used by the text flow layout") {
                    Picker("", selection: vm.deferred(\.htmlTextFlowParagraph)) {
                        ForEach(Array(paragraphs.enumerated()), id: \.offset) { index, title in
                            Text(title)
                                .frame(minWidth: 180, alignment: .leading)
                                .tag(index)
                        }
                    }
                    .pickerStyle(.menu)
                    .disabled(vm.htmlLayoutMode != 1)
                }

                SettingRow("Package", help: "Package the HTML and its resources as a ZIP archive") {
                    Toggle("Package as ZIP", isOn: vm.deferred(\.htmlPackageZip)).toggleStyle(.checkbox)
                }
            }

            Spacer()
        }
    }
}

// MARK: - Image

struct ImageSettingsView: View {
    @EnvironmentObject private var vm: ConverterViewModel

    var body: some View {
        VStack(spacing: 10) {
            SettingsGrid {
                SettingRow("Image format", help: "Output image type used when Output format is Image") {
                    Picker("", selection: vm.deferred(\.imageFormat)) {
                        ForEach(ImageFormat.allCases) { type in
                            HStack(spacing: 6) {
                                Image(type.iconName)
                                Text(type.displayName)
                            }
                            // Minimum width goes on the menu items so the popup
                            // button stays left aligned and localized titles grow
                            // the button instead of being truncated.
                            .frame(minWidth: 120, alignment: .leading)
                            .tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                }

                SettingRow("DPI") {
                    Picker("", selection: vm.deferred(\.imageOutputDPI)) {
                        ForEach(ConverterViewModel.dpiValues, id: \.self) { Text("\($0) DPI").tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 440)
                }

                SettingRow("Quality") {
                    Picker("", selection: vm.deferred(\.imageOutputQualityIndex)) {
                        ForEach(Array(ConverterViewModel.qualityLabels.enumerated()), id: \.offset) { index, label in
                            Text(label)
                                .frame(minWidth: 200, alignment: .leading)
                                .tag(index)
                        }
                    }
                    .pickerStyle(.menu)
                }

                SettingRow("Options") {
                    Toggle("Anti-alias (font smoothing)", isOn: vm.deferred(\.imageAntiAlias)).toggleStyle(.checkbox)
                    Toggle("Package as ZIP", isOn: vm.deferred(\.imagePackageZip)).toggleStyle(.checkbox)
                }
            }

            Spacer()
        }
    }
}

// MARK: - Element

struct ElementSettingsView: View {
    @EnvironmentObject private var vm: ConverterViewModel

    var body: some View {
        VStack(spacing: 10) {
            SettingsGrid {
                SettingRow("Quality") {
                    Picker("", selection: vm.deferred(\.elementQualityIndex)) {
                        ForEach(Array(ConverterViewModel.qualityLabels.enumerated()), id: \.offset) { index, label in
                            Text(label)
                                .frame(minWidth: 200, alignment: .leading)
                                .tag(index)
                        }
                    }
                    .pickerStyle(.menu)
                }

                SettingRow("Package") {
                    Toggle("Package as ZIP", isOn: vm.deferred(\.elementPackageZip)).toggleStyle(.checkbox)
                }
            }

            Spacer()
        }
    }
}

// MARK: - OCR
//
// Mirrors the Objective-C demo: left column with the OCR switch / resolution /
// scan pre-processing, right column with the selected-language summary and a
// 3-column language check-box grid.

struct OCRSettingsView: View {
    @EnvironmentObject private var vm: ConverterViewModel

    private let columns = Array(repeating: GridItem(.flexible(), alignment: .leading), count: 3)

    var body: some View {
        HStack(alignment: .top, spacing: 30) {

            // Left column
            VStack(alignment: .leading, spacing: 14) {
                Toggle("Enable OCR recognition", isOn: vm.deferred(\.ocrEnabled))
                    .toggleStyle(.checkbox)
                    .foregroundColor(.red)
                    .font(.system(size: 13, weight: .semibold))

                Text("Resolution(DPI):")

                Picker("", selection: vm.deferred(\.ocrDPI)) {
                    ForEach(ConverterViewModel.ocrDPIValues, id: \.self) { Text("\($0)").tag($0) }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(maxWidth: 280)
                .disabled(!vm.ocrEnabled)

                Toggle("Scan pre-processing", isOn: vm.deferred(\.ocrImageScan))
                    .toggleStyle(.checkbox)
                    .disabled(!vm.ocrEnabled)

                Spacer()
            }

            // Right column
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Selected Language (note order):")
                    Spacer()
                    Text(verbatim: selectedLanguageSummary)
                        .foregroundColor(.red)
                }

                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.yellow)
                    Text("Suggest combining the end of 'English' with other languages")
                        .foregroundStyle(.secondary)
                }
                .font(.callout)

                LazyVGrid(columns: columns, alignment: .leading, spacing: 9) {
                    ForEach(ConverterViewModel.ocrLanguages) { language in
                        Toggle(language.displayName, isOn: Binding(
                            get: { vm.ocrSelectedLanguages.contains(language.id) },
                            set: { isOn in
                                DispatchQueue.main.async { vm.toggleOCRLanguage(language.id, isOn: isOn) }
                            }
                        ))
                        .toggleStyle(.checkbox)
                        .disabled(!vm.ocrEnabled)
                    }
                }

                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// The combined Tesseract language string, e.g. "chi_sim+eng".
    private var selectedLanguageSummary: String {
        let ordered = ConverterViewModel.ocrLanguages.map { $0.id }.filter { vm.ocrSelectedLanguages.contains($0) }
        return ordered.isEmpty ? " " : ordered.joined(separator: "+")
    }
}
