//
//  FPAppDelegate.h
//  PDF to Word
//
//  Created by James Wei on 4/2/26.
//  Copyright (c) 2026 Flyingbee Software. All rights reserved.
//

// Mac Developer Library
// https://developer.apple.com/library/mac/navigation/


#import <Cocoa/Cocoa.h>


#import <FPPDFFramework/FPPDFFramework.h>
#import <FPPDFFramework/FPPDF2AllConverterWrapper.h>



// Main application delegate for the FPPDFFramework Demo.
// Manages UI controls, PDF conversion settings, and OCR language configuration.
@interface FPAppDelegate : NSObject <NSApplicationDelegate>
{
    // Multi-threaded PDF converter instance
    FPPDF2AllConverterWrapper* pdfConverterMutliThread;
    IBOutlet NSTextField *tf_sourePath;         // Input PDF file path
    IBOutlet NSTextField *tf_sourePassword;     // Password for encrypted PDF files
    IBOutlet NSProgressIndicator* pi_indicator; // Progress indicator animation
    IBOutlet NSTextField *tf_progress;          // Progress status text field
    IBOutlet NSPopUpButton *pub_outputformat;   // Output format selector
    
    IBOutlet NSTextField *tf_license;           // License information display
    
    // General Settings
    IBOutlet NSTabView* tbv_settings;           // Tab view for format-specific settings
    IBOutlet NSButton *btn_openAfter;           // Auto-open file after conversion
    
    // Page Range Settings
    IBOutlet NSSegmentedControl *sc_pageRange;  // Page range mode selector (All/First 10/First 3/First 1/Custom)
    IBOutlet NSTextField *tf_pageRange;         // Custom page range input (e.g. "1,3-5")
    
    // Multi-thread Settings
    IBOutlet NSSegmentedControl *sc_multiThread; // Thread count mode selector
    IBOutlet NSTextField *tf_multiThread;        // Custom thread count input
    
    // Global Image Settings
    IBOutlet NSSegmentedControl *sc_imageDPI;     // Image DPI selector
    IBOutlet NSSegmentedControl *sc_imageQuality;  // Image quality selector
    
    // Word (DOCX) Settings
    IBOutlet NSButton *docx_btn_trimBlankSpace;    // Trim blank spaces option
    IBOutlet NSButton *docx_btn_mergeParagraph;    // Merge paragraphs option
    IBOutlet NSButton *docx_btn_enableShapToImage; // Convert shapes to images option
    IBOutlet NSButton *docx_btn_enableMergeImages; // Merge intersecting images option
    IBOutlet NSSegmentedControl *docx_imageDPI;    // Word output image DPI
    IBOutlet NSPopUpButton *docx_pub_outline;      // Document outline generation mode
    
    // Excel (XLSX) Settings
    IBOutlet NSButton *xlsx_btn_allInOneSheet;     // Put all pages into one sheet
    IBOutlet NSButton *xlsx_btn_recognizeNumber;   // Enable number recognition
    
    IBOutlet NSPopUpButton *xlsx_pub_AIOStyle;          // All-in-one sheet style
    IBOutlet NSPopUpButton *xlsx_pub_outputFormat;      // Excel output format option
    IBOutlet NSPopUpButton *xlsx_pub_ThousandSeparator;  // Thousand separator style
    IBOutlet NSPopUpButton *xlsx_pub_OverlapText;       // Overlap text handling mode
    IBOutlet NSButton *xlsx_csv_btn_isPackageZip;       // Package CSV files as ZIP
    
    // Image Output Settings
    IBOutlet NSSegmentedControl *image_sc_imageType;    // Image format selector (JPEG, PNG, BMP, etc.)
    IBOutlet NSSegmentedControl *image_sc_imageDPI;     // Image output DPI
    IBOutlet NSSegmentedControl *image_sc_imageQuality;  // Image output quality
    IBOutlet NSButton *image_btn_isPackageZip;          // Package images as ZIP
    IBOutlet NSButton *image_btn_isAntiAlias;           // Enable anti-aliasing
    
    // Element Output Settings
    IBOutlet NSSegmentedControl *element_sc_imageQuality; // Element image quality
    IBOutlet NSButton *element_btn_isPackageZip;         // Package elements as ZIP
    
    // HTML Output Settings
    IBOutlet NSPopUpButton *html_pub_layoutMode;         // HTML layout mode
    IBOutlet NSPopUpButton *html_pub_mergeResource;      // Resource merging option
    IBOutlet NSPopUpButton *html_pub_navigationBar;      // Navigation bar option
    IBOutlet NSPopUpButton *html_pub_textFlowParagraph;  // Text flow paragraph mode
    IBOutlet NSButton *html_btn_isPackageZip;            // Package HTML as ZIP
    
    // OCR Settings
    IBOutlet NSButton *ocr_btn_isEnableOCR;         // Enable OCR processing
    IBOutlet NSButton *ocr_btn_isEnableImageScan;   // Enable image scan mode
    IBOutlet NSSegmentedControl *ocr_sc_imageDPI;   // OCR image DPI
    IBOutlet NSTextField *ocr_tf_languages;          // OCR language codes display (e.g. "eng+chi_sim")
    IBOutlet NSButton *ocr_btn_lang_English;         // English
    IBOutlet NSButton *ocr_btn_lang_German;          // German
    IBOutlet NSButton *ocr_btn_lang_Japanese;        // Japanese
    IBOutlet NSButton *ocr_btn_lang_French;          // French
    IBOutlet NSButton *ocr_btn_lang_Italian;         // Italian
    IBOutlet NSButton *ocr_btn_lang_Portuguese;      // Portuguese
    IBOutlet NSButton *ocr_btn_lang_Spanish;         // Spanish
    IBOutlet NSButton *ocr_btn_lang_Russian;         // Russian
    IBOutlet NSButton *ocr_btn_lang_Korean;          // Korean
    IBOutlet NSButton *ocr_btn_lang_Dutch;           // Dutch
    IBOutlet NSButton *ocr_btn_lang_Polish;          // Polish
    IBOutlet NSButton *ocr_btn_lang_Swedish;         // Swedish
    IBOutlet NSButton *ocr_btn_lang_Arab;            // Arabic
    IBOutlet NSButton *ocr_btn_lang_Turkish;         // Turkish
    IBOutlet NSButton *ocr_btn_lang_Chinese_Simplified;  // Simplified Chinese
    IBOutlet NSButton *ocr_btn_lang_Chinese_Traditional; // Traditional Chinese
    IBOutlet NSButton *ocr_btn_lang_Vietnamese;      // Vietnamese
    IBOutlet NSButton *ocr_btn_lang_Indonesian;      // Indonesian
    IBOutlet NSButton *ocr_btn_lang_Ukrainian;       // Ukrainian
    IBOutlet NSButton *ocr_btn_lang_Czech;           // Czech
    
    // Array of all OCR language checkbox buttons (in order)
    NSMutableArray* ocrAllLanguageButtons;
    // Array of OCR language codes (e.g. "eng", "chi_sim") matching the button order
    NSMutableArray* ocrAllLanguageCodes;
    // Array of currently selected OCR language codes
    NSMutableArray* ocrSelectedLanguageCodes;
    
}
@property (assign) IBOutlet NSWindow *window;                // Main application window
@property (nonatomic, retain)NSArray* pathArray;              // Array of selected PDF file URLs
@property (nonatomic, retain)NSMutableArray* readyPathArray;  // Queue of PDF files pending conversion
@property (nonatomic, retain)NSMutableArray* restoredPathArray; // Restored PDF URLs from saved bookmarks
@property (nonatomic, retain) IBOutlet NSTextField *tf_outputPath; // Output directory path display
@property (nonatomic, retain) NSURL *outputDirectoryURL;      // Security-scoped output directory URL

@end
