//
//  FPPDFConverterBridge.h
//  FPPDFFrameworkDemoMac_Swift
//
//  Created by James Wei on 9/4/26.
//  Copyright (c) 2026 Flyingbee Software. All rights reserved.
//
//  Objective-C++ bridge between Swift and the C++ based FPPDFFramework API.
//
//  The SDK's FPPDFOptions (and its sub-option classes) are pure C++ classes
//  that Swift cannot use directly. This header is plain Objective-C so it can
//  be imported from the Swift bridging header, while the .mm implementation
//  translates the options below into C++ objects and drives
//  FPPDF2AllConverterWrapper.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Word (DOCX) options

@interface FPPDFWordOptionsBridge : NSObject
@property (nonatomic, assign) BOOL isTrimmingBlankSpaceCharacters;
@property (nonatomic, assign) BOOL isMergeParagraphs;
/// FPWordOption_Outline_Type (0 = none, 1 = PDF outline, 2 = detect outline)
@property (nonatomic, assign) NSInteger outlineType;
@property (nonatomic, assign) BOOL enableShapeToImage;
@property (nonatomic, assign) BOOL enableMergeIntersectImages;
/// FPWordOption_HTML_LayoutMode (0 = exact page, 1 = text flow)
@property (nonatomic, assign) NSInteger htmlLayoutMode;
/// FPWordOption_HTML_Merge_Resource (0..3)
@property (nonatomic, assign) NSInteger htmlMergeResource;
/// FPWordOption_HTML_NavigationBar (0 = none, 1 = PDF viewer)
@property (nonatomic, assign) NSInteger htmlNavigationBar;
/// FPWordOption_HTML_TextFlow_Paragraph (0 = line break, 1 = first line indent)
@property (nonatomic, assign) NSInteger htmlTextFlowParagraph;
/// FPWordOption_HTML_Package (0 = none, 1 = zip)
@property (nonatomic, assign) NSInteger htmlPackage;
@end

#pragma mark - Excel (XLSX/CSV) options

@interface FPPDFExcelOptionsBridge : NSObject
/// FPPDFToExcelFormatOption (0..2)
@property (nonatomic, assign) NSInteger excelFormatOption;
/// FPPDFToExcelthousandSeparator (0..4)
@property (nonatomic, assign) NSInteger thousandSeparator;
@property (nonatomic, assign) BOOL allInOneSheet;
/// YES = append rows, NO = append columns
@property (nonatomic, assign) BOOL allInOneSheetAddToRow;
@property (nonatomic, assign) BOOL recognizeNumber;
/// FPPDFToExcelOverlapText (0 = auto, 1 = merge, 2 = split)
@property (nonatomic, assign) NSInteger overlapText;
@property (nonatomic, assign) BOOL isCSVPackageZip;
@end

#pragma mark - Image output options

@interface FPPDFImageOptionsBridge : NSObject
/// FPPDF2ImageOptions_Format (0 = JPEG, 1 = PNG, 2 = BMP, 3 = GIF, 4 = TIFF, 5 = TGA, 6 = JPEG2000)
@property (nonatomic, assign) NSInteger imageFormat;
@property (nonatomic, assign) int imageDPI;
@property (nonatomic, assign) float imageQuality;
@property (nonatomic, assign) BOOL isPackageZip;
@property (nonatomic, assign) BOOL isAntiAlias;
@end

#pragma mark - Element output options

@interface FPPDFElementOptionsBridge : NSObject
@property (nonatomic, assign) float imageQuality;
@property (nonatomic, assign) BOOL isPackageZip;
@end

#pragma mark - OCR options

@interface FPPDFOCROptionsBridge : NSObject
/// OCR language codes joined by "+", e.g. "chi_sim+eng"
@property (nonatomic, copy) NSString *language;
/// FPPDFOCREngineMode (0 = tesseract only, 1 = LSTM only, 2 = combined, 3 = default)
@property (nonatomic, assign) NSInteger engineMode;
@property (nonatomic, assign) unsigned int resizeDPI;
@property (nonatomic, assign) float minConfidence;
@property (nonatomic, assign) BOOL isEnableImageScan;
@end

#pragma mark - Global conversion options

@interface FPPDFConversionOptions : NSObject
@property (nonatomic, assign) int isParserAnnots;
@property (nonatomic, assign) int threadMax;
@property (nonatomic, assign) int imageDPI;
@property (nonatomic, assign) float imageQuality;

@property (nonatomic, strong) FPPDFWordOptionsBridge *wordOptions;
@property (nonatomic, strong) FPPDFExcelOptionsBridge *excelOptions;
@property (nonatomic, strong) FPPDFImageOptionsBridge *imageOptions;
@property (nonatomic, strong) FPPDFElementOptionsBridge *elementOptions;
@property (nonatomic, strong) FPPDFOCROptionsBridge *ocrOptions;

@property (nonatomic, assign) BOOL isEnableOCR;
@end

#pragma mark - Converter bridge

typedef void(^FPPDFBridgeDidStartHandler)(BOOL success, NSString * _Nullable errorInfo);
typedef void(^FPPDFBridgeProgressHandler)(NSInteger currentPage, NSInteger totalPages, BOOL success, NSString * _Nullable errorInfo);
typedef void(^FPPDFBridgeWillSaveHandler)(void);
typedef void(^FPPDFBridgeCompletionHandler)(BOOL success, NSString * _Nullable errorInfo);

@interface FPPDFConverterBridge : NSObject

/// YES while a conversion is running
@property (nonatomic, readonly) BOOL isConverting;
/// Destination path of the last conversion
@property (nonatomic, readonly, copy) NSString *destPath;

/// SDK debug log file path
+ (NSString *)debugLogPath;

/// License information (static C++ helpers wrapped for Swift)
+ (NSString *)sdkLicenseOrganization;
+ (NSString *)sdkLicenseExpiredDate;
+ (BOOL)isSDKLicenseAuthExpiredDate;

/// Convert a single PDF file. page numbers in pageIndexes are 1-based.
- (void)convertPDFAtPath:(NSString *)pdfPath
                password:(nullable NSString *)password
             pageIndexes:(nullable NSArray<NSNumber *> *)pageIndexes
            outputFormat:(NSString *)outputFormat
                destPath:(NSString *)destPath
                 options:(FPPDFConversionOptions *)options
          isInBackground:(BOOL)isInBackground
         didStartHandler:(nullable FPPDFBridgeDidStartHandler)didStartHandler
         progressHandler:(nullable FPPDFBridgeProgressHandler)progressHandler
        willSaveHandler:(nullable FPPDFBridgeWillSaveHandler)willSaveHandler
      completionHandler:(FPPDFBridgeCompletionHandler)completionHandler;

/// Cancel the running conversion
- (BOOL)cancelConversion;

@end

NS_ASSUME_NONNULL_END
