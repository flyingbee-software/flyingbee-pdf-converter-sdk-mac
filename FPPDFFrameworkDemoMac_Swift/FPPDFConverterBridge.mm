//
//  FPPDFConverterBridge.mm
//  FPPDFFrameworkDemoMac_Swift
//
//  Created by James Wei on 9/4/26.
//  Copyright (c) 2026 Flyingbee Software. All rights reserved.
//

#import "FPPDFConverterBridge.h"

#import <FPPDFFramework/FPPDFFramework.h>
#import <FPPDFFramework/FPPDF2AllConverterWrapper.h>
#import <FPPDFFramework/FPPDFOptions.h>

@implementation FPPDFWordOptionsBridge
@end

@implementation FPPDFExcelOptionsBridge
@end

@implementation FPPDFImageOptionsBridge
@end

@implementation FPPDFElementOptionsBridge
@end

@implementation FPPDFOCROptionsBridge
@end

@implementation FPPDFConversionOptions

- (instancetype)init {
    self = [super init];
    if (self) {
        _wordOptions   = [[FPPDFWordOptionsBridge alloc] init];
        _excelOptions  = [[FPPDFExcelOptionsBridge alloc] init];
        _imageOptions  = [[FPPDFImageOptionsBridge alloc] init];
        _elementOptions = [[FPPDFElementOptionsBridge alloc] init];
        _ocrOptions    = [[FPPDFOCROptionsBridge alloc] init];
    }
    return self;
}

@end

@implementation FPPDFConverterBridge {
    FPPDF2AllConverterWrapper *_converter;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _converter = [[FPPDF2AllConverterWrapper alloc] init];
    }
    return self;
}

- (BOOL)isConverting {
    return _converter.isConverting;
}

- (NSString *)destPath {
    return _converter.destPath;
}

+ (NSString *)debugLogPath {
    return [FPPDF2AllConverterWrapper DebugLogPath];
}

+ (NSString *)sdkLicenseOrganization {
    const char *org = FPPDF2AllConverter::GetSDKLicenseOrganization();
    return org ? [NSString stringWithUTF8String:org] : @"";
}

+ (NSString *)sdkLicenseExpiredDate {
    const char *date = FPPDF2AllConverter::GetSDKLicenseExpiredDate();
    return date ? [NSString stringWithUTF8String:date] : @"";
}

+ (BOOL)isSDKLicenseAuthExpiredDate {
    return FPPDF2AllConverter::isSDKLicenseAuth_ExpiredDate() ? YES : NO;
}

#pragma mark - Options translation

// Builds the C++ FPPDFOptions from the Swift/ObjC friendly options object.
// The returned object is heap allocated; caller must delete it.
static FPPDFOptions *FPPDFBuildCppOptions(FPPDFConversionOptions *options) {
    FPPDFOptions *moreOptions = new FPPDFOptions();

    moreOptions->isParserAnnots = options.isParserAnnots;
    moreOptions->threadMax      = options.threadMax;
    moreOptions->imageDPI       = options.imageDPI;
    moreOptions->imageQuality   = options.imageQuality;

    // --- Word (DOCX) options ---
    moreOptions->wordOptions->isTrimmingBlankSpaceCharacters = options.wordOptions.isTrimmingBlankSpaceCharacters;
    moreOptions->wordOptions->isMergeParagraphs              = options.wordOptions.isMergeParagraphs;
    moreOptions->wordOptions->outlineType                    = (FPWordOption_Outline_Type)options.wordOptions.outlineType;
    moreOptions->wordOptions->enableShapeToImage             = options.wordOptions.enableShapeToImage;
    moreOptions->wordOptions->enableMergeIntersectImages     = options.wordOptions.enableMergeIntersectImages;

    // --- HTML options (carried on wordOptions, same as the ObjC demo) ---
    moreOptions->wordOptions->htmlLayoutMode        = (FPWordOption_HTML_LayoutMode)options.wordOptions.htmlLayoutMode;
    moreOptions->wordOptions->htmlMergeResource     = (FPWordOption_HTML_Merge_Resource)options.wordOptions.htmlMergeResource;
    moreOptions->wordOptions->htmlNavigationBar     = (FPWordOption_HTML_NavigationBar)options.wordOptions.htmlNavigationBar;
    moreOptions->wordOptions->htmlTextFlowParagraph = (FPWordOption_HTML_TextFlow_Paragraph)options.wordOptions.htmlTextFlowParagraph;
    moreOptions->wordOptions->htmlPackage           = (FPWordOption_HTML_Package)options.wordOptions.htmlPackage;

    // --- Excel (XLSX/CSV) options ---
    moreOptions->excelOptions->excelFormatOption     = (FPPDFToExcelFormatOption)options.excelOptions.excelFormatOption;
    moreOptions->excelOptions->thousandSeparator     = (FPPDFToExcelthousandSeparator)options.excelOptions.thousandSeparator;
    moreOptions->excelOptions->allInOneSheet         = options.excelOptions.allInOneSheet;
    moreOptions->excelOptions->allInOneSheetAddToRow = options.excelOptions.allInOneSheetAddToRow;
    moreOptions->excelOptions->recognizeNumber       = options.excelOptions.recognizeNumber;
    moreOptions->excelOptions->overlapText           = (FPPDFToExcelOverlapText)options.excelOptions.overlapText;
    moreOptions->excelOptions->isCSVPackageZip       = options.excelOptions.isCSVPackageZip ? 1 : 0;

    // --- Image output options ---
    moreOptions->imageOptions->imageFormat   = (FPPDF2ImageOptions_Format)options.imageOptions.imageFormat;
    moreOptions->imageOptions->imageDPI      = options.imageOptions.imageDPI;
    moreOptions->imageOptions->imageQuality  = options.imageOptions.imageQuality;
    moreOptions->imageOptions->isPackageZip  = options.imageOptions.isPackageZip ? 1 : 0;
    moreOptions->imageOptions->isAntiAlias   = options.imageOptions.isAntiAlias ? true : false;

    // --- Element output options ---
    moreOptions->elementOptions->imageQuality = options.elementOptions.imageQuality;
    moreOptions->elementOptions->isPackageZip = options.elementOptions.isPackageZip ? 1 : 0;

    // --- OCR options ---
    moreOptions->isEnableOCR = options.isEnableOCR;
    if (options.ocrOptions.language.length > 0) {
        snprintf(moreOptions->ocrOptions->language,
                 sizeof(moreOptions->ocrOptions->language),
                 "%s", options.ocrOptions.language.UTF8String);
    } else {
        snprintf(moreOptions->ocrOptions->language,
                 sizeof(moreOptions->ocrOptions->language),
                 "%s", "chi_sim+eng");
    }
    moreOptions->ocrOptions->engineMode       = (FPPDFOCREngineMode)options.ocrOptions.engineMode;
    moreOptions->ocrOptions->resizeDPI        = options.ocrOptions.resizeDPI;
    moreOptions->ocrOptions->minConfidence    = options.ocrOptions.minConfidence;
    moreOptions->ocrOptions->isEnableImageScan = options.ocrOptions.isEnableImageScan;

    return moreOptions;
}

#pragma mark - Conversion

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
      completionHandler:(FPPDFBridgeCompletionHandler)completionHandler
{
    // Keep the C++ options alive for the duration of the (asynchronous) call.
    FPPDFOptions *cppOptions = FPPDFBuildCppOptions(options);

    [_converter convertPDFAtPath:pdfPath
                        password:password
                     pageIndexes:pageIndexes
                    outputFormat:outputFormat
                        destPath:destPath
                     moreOptions:cppOptions
                  isInBackground:isInBackground
                didStartHandler:^(BOOL success, NSString *error) {
        if (didStartHandler) didStartHandler(success, error);
    }
                 progressHandler:^(NSInteger currentPage, NSInteger total, BOOL success, NSString *error) {
        if (progressHandler) progressHandler(currentPage, total, success, error);
    }
               willSaveHandler:^{
        if (willSaveHandler) willSaveHandler();
    }
             completionHandler:^(BOOL success, NSString *error) {
        completionHandler(success, error);
    }];

    // The wrapper copies the options internally when the conversion starts,
    // so it is safe to release them here (same pattern as the ObjC demo).
    delete cppOptions;
}

- (BOOL)cancelConversion {
    return [_converter cancelConversion];
}

@end
