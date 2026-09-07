//
//  FPPDF2AllConverterWrapper.h
//  FPPDFFramework
//
//  Created by James Wei on 4/2/26.
//  Copyright (c) 2026 Flyingbee Software. All rights reserved.
//

#if defined(__APPLE__)
#import <Foundation/Foundation.h>
#import <FPPDFFramework/FPPDFOptions.h>
#import <FPPDFFramework/FPPDFFramework.h>


NS_ASSUME_NONNULL_BEGIN


// Callback block type definition
typedef void(^FPPDFConversionCompletionHandler)(BOOL success, NSString * _Nullable errorInfo);
typedef void(^FPPDFConversionDidStartHandler)(BOOL success, NSString * _Nullable errorInfo);
typedef void(^FPPDFConversionPageProgressHandler)(NSInteger currentPageIndex, NSInteger totalPages, BOOL success, NSString * _Nullable errorInfo);
typedef void(^FPPDFConversionWillSaveHandler)(void);

@interface FPPDF2AllConverterWrapper : NSObject

// Initialize converter
- (instancetype)init;
// Is the conversion currently in progress
@property (nonatomic, assign, readonly) BOOL isConverting;
@property (nonatomic, retain, readonly) NSString* destPath;
// Log file path
+ (NSString*)DebugLogPath;

#pragma mark - PDF to Office (Word/Excel/PPT, etc.)
// Convert a single PDF file
// @param pdfPath PDF file path (sandbox path)
// @param password PDF password (can be nil)
// The page number array to be converted by @ parampageIndexes (starting from 0), nil represents all
// @param outputting format (such as @ "docx", @ "xlsx")
// @param destPath Output file path
// @param isInBackground running in the background
// @param didStartHandler starts callback
// @param progressHandler page progress callback
// @param willSaveHandler is about to save the document callback
// @param complementHandler completes callback
- (void)convertPDFAtPath:(NSString *)pdfPath
                password:(nullable NSString *)password
             pageIndexes:(nullable NSArray<NSNumber *> *)pageIndexes
            outputFormat:(NSString *)outputFormat
               destPath:(NSString *)destPath
             moreOptions:(FPPDFOptions *)moreOptions
          isInBackground:(BOOL)isInBackground
           didStartHandler:(nullable FPPDFConversionDidStartHandler)didStartHandler
         progressHandler:(nullable FPPDFConversionPageProgressHandler)progressHandler
        willSaveHandler:(nullable FPPDFConversionWillSaveHandler)willSaveHandler
      completionHandler:(FPPDFConversionCompletionHandler)completionHandler;

#pragma mark - Convert images to PDF
// Merge multiple images into a PDF
- (void)convertImagesToPDF:(NSArray<NSString *> *)imagePaths
                 outputPath:(NSString *)outputPath
            paperSizeAuto:(BOOL)paperSizeAuto
                pageWidth:(double)pageWidth
               pageHeight:(double)pageHeight
              pageMargins:(double)pageMargins
           orientationLandscape:(BOOL)orientationLandscape // YES = landscape
               scaleMethod:(NSInteger)scaleMethod // Corresponding FPPDFOptions_ScaleMethod enumeration value
               cropWidth:(BOOL)cropWidth
              cropHeight:(BOOL)cropHeight
                   title:(nullable NSString *)title
                  author:(nullable NSString *)author
                keywords:(nullable NSString *)keywords
                 subject:(nullable NSString *)subject
                 creator:(nullable NSString *)creator
          isInBackground:(BOOL)isInBackground
       completionHandler:(FPPDFConversionCompletionHandler)completionHandler;

#pragma mark - Text to Word
// Convert text files to Word
- (void)convertTextToWordAtPath:(NSString *)textPath
                     outputPath:(NSString *)outputPath
                  paperSizeAuto:(BOOL)paperSizeAuto
                      pageWidth:(double)pageWidth
                     pageHeight:(double)pageHeight
                    pageMargins:(double)pageMargins
           orientationLandscape:(BOOL)orientationLandscape
                       fontName:(nullable NSString *)fontName
                       fontSize:(float)fontSize
                    columnCount:(NSInteger)columnCount
                 isInBackground:(BOOL)isInBackground
              completionHandler:(FPPDFConversionCompletionHandler)completionHandler;

// Cancel the current conversion
- (BOOL)cancelConversion;

@end

NS_ASSUME_NONNULL_END

#endif
