//
//  ContentView.swift
//  FPPDFFrameworkDemoMac_Swift
//
//  Main window of the SwiftUI demo. The layout mirrors the Objective-C demo's
//  MainMenu.xib: input file / password row, output folder row, output format
//  row, tabbed per-format settings, page range & thread rows at the bottom,
//  and the action bar with license info.
//
//  The top form is a SwiftUI `Grid`: the label column is sized to the widest
//  label, so rows stay aligned like the Objective-C demo and localized labels
//  are never truncated. Controls use flexible (min/max) widths instead of
//  fixed ones so longer localized text can grow the control.
//
//  Created by James Wei on 9/4/26.
//  Copyright (c) 2026 Flyingbee Software. All rights reserved.
//

import SwiftUI

/// The per-format settings panes shown in the tab strip below "Output format:".
enum SettingsTab: String, CaseIterable, Identifiable {
    case general, ocr, word, excel, html, image, element

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .general: return "General"
        case .ocr:     return "OCR"
        case .word:    return "Word"
        case .excel:   return "Excel"
        case .html:    return "HTML"
        case .image:   return "Image"
        case .element: return "Element"
        }
    }
}


struct ContentView: View {

    @EnvironmentObject private var vm: ConverterViewModel

    /// Currently selected settings pane.
    @State private var selectedTab: SettingsTab = .general

    var body: some View {
        VStack(spacing: 4) {

            Grid(alignment: .trailingFirstTextBaseline, horizontalSpacing: 8, verticalSpacing: 4) {
                inputFileRow
                selectInputButtonsRow
                outputFolderRow
                formatRow
                settingsTabsRow
                pageRangeRow
                multiThreadsRow
            }

            Divider()

            actionBar

            // Always present: the slot keeps its height whether or not a
            // conversion is running, so showing/hiding the indicator never
            // shifts the rest of the window.
            progressSection

            statusLine
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
        .padding(.bottom, 8)
        .frame(minWidth: 760)
    }

    // MARK: - Row 1: Input file + Password

    private var inputFileRow: some View {
        GridRow {
            sectionLabel("Input file:")

            TextField("/path/to/file.pdf", text: $vm.sourcePathText)
                .textFieldStyle(.roundedBorder)
                .disabled(true)
                .gridCellAnchor(.leading)

            sectionLabel("Password:")

            SecureField("input pdf password", text: $vm.pdfPassword)
                .textFieldStyle(.roundedBorder)
                .frame(minWidth: 150, maxWidth: 230)
                .gridCellAnchor(.leading)
        }
    }

    // MARK: - Row 2: Select input file / Show in Finder

    private var selectInputButtonsRow: some View {
        GridRow {
            // Empty first cell keeps the buttons aligned with the text fields.
            // IMPORTANT: Color.clear is a two-axis-flexible Shape. Left as-is it
            // stretches this Grid row to a huge height (the buttons then float
            // centered with large gaps above/below). Pinning it to zero height
            // makes the row collapse to the buttons' own height. Column width is
            // still driven by the labels in the other rows, so alignment holds.
            Color.clear
                .frame(maxHeight: 0)
                .gridCellUnsizedAxes(.horizontal)

            HStack(spacing: 16) {
                FormButton("Select input file...", minWidth: 165, action: vm.selectPDFFiles)

                FormButton("Show in Finder", minWidth: 150, action: vm.revealSourceFile)

                Spacer(minLength: 0)
            }
            // No `.controlSize(.small)` here on purpose: these two buttons must
            // keep the standard bezel height, matching the "Select..." button in
            // the output folder row. The row height itself is controlled by the
            // zero-height placeholder cell above, not by the button size.
            .gridCellColumns(3)
            .gridCellAnchor(.leading)
        }
    }

    // MARK: - Row 3: Output folder

    private var outputFolderRow: some View {
        GridRow {
            sectionLabel("Output folder:")

            TextField("Select the folder for converted files...", text: $vm.outputPathText)
                .textFieldStyle(.roundedBorder)
                .disabled(true)
                .gridCellAnchor(.leading)

            FormButton("Select...", minWidth: 70, action: vm.selectOutputDirectory)
                .gridCellAnchor(.leading)

            FormButton("Show in Finder", minWidth: 100, action: vm.openOutputFolder)
                .gridCellAnchor(.leading)
        }
    }

    // MARK: - Row 4: Output format + auto open + show log

    private var formatRow: some View {
        GridRow {
            sectionLabel("Output format:")

            HStack(spacing: 12) {
                Picker("", selection: vm.deferred(\.outputFormat)) {
                    ForEach(OutputFormat.allCases) { format in
                        HStack(spacing: 6) {
                            Image(format.iconName)
                            Text(format.displayName)
                        }
                        // The minimum width belongs on the menu items, not on the
                        // picker: a frame around the picker centres its popup button
                        // and detaches it from the left edge of the form.
                        .frame(minWidth: 210, alignment: .leading)
                        .tag(format)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()

                Toggle("Auto open output file", isOn: vm.deferred(\.openAfterConversion))
                    .toggleStyle(.checkbox)

                Spacer(minLength: 16)

                showLogButton
            }
            .gridCellColumns(3)
            .gridCellAnchor(.leading)
        }
    }

    /// The yellow "Show log in Finder" button.
    private var showLogButton: some View {
        Button {
            vm.revealLogFolder()
        } label: {
            Text("Show log in Finder")
                .padding(.horizontal, 14)
                .padding(.vertical, 4)
                .background(Color(red: 1.0, green: 0.84, blue: 0.28))
                .foregroundColor(.black)
                .cornerRadius(6)
        }
        .buttonStyle(.plain)
        .help("Open the SDK log file location in Finder")
    }

    // MARK: - Tabbed settings (General | OCR | Word | Excel | HTML | Image | Element)

    private var settingsTabsRow: some View {
        GridRow {
            settingsTabs
                .gridCellColumns(4)
                .gridCellAnchor(.leading)
        }
    }

    private var settingsTabs: some View {
        VStack(spacing: 6) {

            // Tab strip.
            // A plain SwiftUI `TabView` hoists its tab bar to the top of the window
            // on macOS, which breaks the layout, so the switcher is built here with a
            // segmented picker instead. It stays exactly where it is placed.
            // Flexible width so localized tab titles are never clipped.
            Picker("", selection: $selectedTab) {
                ForEach(SettingsTab.allCases) { Text($0.displayName).tag($0) }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(maxWidth: 560)

            currentPane
                .settingsPane()
                .environmentObject(vm)
                .frame(minHeight: 205)
        }
    }

    /// The settings view that belongs to the currently selected tab.
    @ViewBuilder
    private var currentPane: some View {
        switch selectedTab {
        case .general: GeneralSettingsView()
        case .ocr:     OCRSettingsView()
        case .word:    WordSettingsView()
        case .excel:   ExcelSettingsView()
        case .html:    HTMLSettingsView()
        case .image:   ImageSettingsView()
        case .element: ElementSettingsView()
        }
    }

    // MARK: - Page Range row

    private var pageRangeRow: some View {
        GridRow {
            sectionLabel("Page Range:")

            Picker("", selection: vm.deferred(\.pageRangeMode)) {
                ForEach(PageRangeMode.allCases) { Text($0.displayName).tag($0) }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(maxWidth: 430)
            .gridCellAnchor(.leading)

            TextField("2", text: $vm.customPageRange)
                .textFieldStyle(.roundedBorder)
                .frame(width: 64)
                .disabled(vm.pageRangeMode != .custom)
                .gridCellAnchor(.leading)

            HStack {
                Text("Pages")
                Spacer()
                Text(verbatim: "Eg: pages 1, 5, 3-12")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .gridCellAnchor(.leading)
        }
    }

    // MARK: - Multi-Threads row

    private var multiThreadsRow: some View {
        GridRow {
            sectionLabel("Multi-Threads:")

            Picker("", selection: vm.deferred(\.threadMode)) {
                ForEach(ThreadMode.allCases) { Text($0.displayName).tag($0) }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(maxWidth: 340)
            .gridCellAnchor(.leading)

            TextField("3", text: $vm.customThreadCount)
                .textFieldStyle(.roundedBorder)
                .frame(width: 64)
                .disabled(vm.threadMode != .custom)
                .gridCellAnchor(.leading)

            HStack {
                Text("Threads")
                Spacer()
            }
            .gridCellAnchor(.leading)
        }
    }

    // MARK: - Action bar: Start / Stop / Show output + license info

    private var actionBar: some View {
        HStack(alignment: .center, spacing: 10) {
            Spacer()

            Button {
                vm.startConversion()
            } label: {
                Label("Start Conversion", systemImage: "play.fill")
                    .padding(.horizontal, 16)
                    .padding(.vertical, 5)
                    .background(vm.isConverting ? Color.gray : Color(red: 0.16, green: 0.62, blue: 0.27))
                    .foregroundColor(.white)
                    .cornerRadius(6)
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.return, modifiers: .command)
            .disabled(vm.isConverting)

            Button {
                vm.stopConversion()
            } label: {
                Text("Stop")
                    .padding(.horizontal, 22)
                    .padding(.vertical, 5)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color(nsColor: .separatorColor))
                    )
            }
            .buttonStyle(.plain)
            .disabled(!vm.isConverting)

            Button {
                vm.openOutputFolder()
            } label: {
                Text("Show output in Finder")
                    .padding(.horizontal, 14)
                    .padding(.vertical, 5)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color(nsColor: .separatorColor))
                    )
            }
            .buttonStyle(.plain)

            Spacer()

            // License block, right aligned like the Objective-C demo
            VStack(alignment: .trailing, spacing: 1) {
                HStack(spacing: 3) {
                    Image(systemName: "figure.wave")
                    Text(verbatim: "License to \(vm.licenseOrganization)")
                }
                HStack(spacing: 3) {
                    Image(systemName: "clock")
                    Text(verbatim: "Expiration date: \(vm.licenseExpiredDate)")
                }
                if vm.licenseExpired {
                    HStack(spacing: 3) {
                        Image(systemName: "xmark.square.fill")
                        Text("License Expired")
                    }
                    .foregroundColor(.red)
                }
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
    }

    // MARK: - Progress indicator (shown while a conversion is running)

    /// Height reserved for the progress row. The slot is always in the layout
    /// (empty when idle), so switching to and from the converting state never
    /// moves the action bar, the status line or the window height.
    private static let progressRowHeight: CGFloat = 20

    /// A determinate bar driven by `ConverterViewModel.progressValue`
    /// (current page / total pages). The row itself is always laid out; only
    /// its contents are conditional, which keeps the surrounding UI stable.
    private var progressSection: some View {
        ZStack {
            if vm.isConverting {
                HStack(spacing: 8) {
                    ProgressView(value: clampedProgress, total: 1.0)
                        .progressViewStyle(.linear)
                        .frame(width: 380, height: 16)

                    Text(verbatim: "\(Int((clampedProgress * 100).rounded()))%")
                        .font(.callout)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                        .frame(width: 42, alignment: .leading)
                }
                .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: Self.progressRowHeight)
        .animation(.easeOut(duration: 0.15), value: vm.isConverting)
    }

    /// Keeps the bar inside 0...1 even if the SDK reports an out-of-range value.
    private var clampedProgress: Double {
        min(max(vm.progressValue, 0), 1)
    }

    // MARK: - Status line (centered, below the action bar)

    private var statusLine: some View {
        Text(verbatim: vm.statusMessage.isEmpty ? " " : vm.statusMessage)
            .font(.callout)
            .foregroundStyle(vm.statusMessage.hasPrefix("❌") ? AnyShapeStyle(.red) : AnyShapeStyle(.primary))
            .textSelection(.enabled)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Helpers

    /// Bold label in the shared label column. The surrounding `Grid` sizes the
    /// column to the widest label, so rows align like the Objective-C demo and
    /// longer localized labels simply widen the column instead of truncating.
    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .fontWeight(.semibold)
    }
}

#Preview {
    ContentView()
        .environmentObject(ConverterViewModel.shared)
        .frame(width: 760, height: 612)
}

// MARK: - Form button

/// A bordered push button used in the form rows.
///
/// The minimum width is applied to the label *inside* the button instead of to
/// the button itself: wrapping a `Button` in `frame(minWidth:)` keeps the
/// button at its natural width and **centres** it inside that frame, which
/// breaks the left alignment of the form (and used to offset the buttons row by
/// ~30pt relative to the input text field). Putting the minimum width on the
/// label keeps the bezel left aligned and lets longer localized titles grow the
/// button instead of being truncated.
private struct FormButton: View {
    let title: String
    let minWidth: CGFloat
    let help: String?
    let action: () -> Void

    init(_ title: String, minWidth: CGFloat, help: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.minWidth = minWidth
        self.help = help
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .frame(minWidth: minWidth, alignment: .center)
        }
        .buttonStyle(.bordered)
        .help(help ?? "")
    }
}
