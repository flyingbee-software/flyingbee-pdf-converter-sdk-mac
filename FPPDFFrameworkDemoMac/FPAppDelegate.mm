//
//  FPAppDelegate.m
//  PDF to Word
//
//  Created by James Wei on 4/2/26.
//  Copyright (c) 2026 Flyingbee Software. All rights reserved.
//

#import "FPAppDelegate.h"
#import <sys/utsname.h>
#import <FPPDFFramework/FPPDFOptions.h>


@implementation FPAppDelegate

#pragma mark - Helper Functions

/**
 *  @brief Reveals the specified file in Finder by selecting it.
 *  @param filePath  The absolute path of the file to reveal.
 */
void RevealFileInFinder(NSString *filePath) {
    NSURL *fileURL = [NSURL fileURLWithPath:filePath];
    [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:@[fileURL]];
}

/**
 *  @brief Restores the previously saved output directory from a security-scoped bookmark.
 *         If the bookmark is stale or invalid, the user is notified via the progress text field.
 */
- (void)restoreOutputDirectory {
    NSData *savedBookmark = [[NSUserDefaults standardUserDefaults] objectForKey:@"OutputDirectoryBookmark"];
    if (!savedBookmark) {
        return;
    }

    NSError *error = nil;
    BOOL isStale = NO;
    NSURL *restoredURL = [NSURL URLByResolvingBookmarkData:savedBookmark
                                                   options:NSURLBookmarkResolutionWithSecurityScope
                                             relativeToURL:nil
                                       bookmarkDataIsStale:&isStale
                                                     error:&error];
    if (restoredURL) {
        if (isStale) {
            tf_progress.stringValue = [NSString stringWithFormat:@"⚠️ The output directory bookmark has expired (files have been moved or deleted)"];
            // Optional: Clear old bookmarks
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"OutputDirectoryBookmark"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            return;
        }

        // Attempt to obtain access permission
        if ([restoredURL startAccessingSecurityScopedResource]) {
            self.outputDirectoryURL = restoredURL; // strong
            self.tf_outputPath.stringValue = [restoredURL path];
            //tf_progress.stringValue = [NSString stringWithFormat:@"✅ Successfully restored output directory: %@", restoredURL];
        } else {
            self.outputDirectoryURL = nil;
            tf_progress.stringValue = [NSString stringWithFormat:@"❌ Failed to restore output directory"];
        }
    } else {
        tf_progress.stringValue = [NSString stringWithFormat:@"❌ Unable to resolve output directory bookmark: %@", error];
    }
}

/**
 *  @brief Restores previously selected PDF file URLs from security-scoped bookmarks.
 *         Updates the source path text field with the first restored file.
 */
- (void)restoreBookmarkedFiles {
    NSArray<NSData *> *savedBookmarks = [[NSUserDefaults standardUserDefaults] objectForKey:@"SavedPDFBookmarks"];
    if (!savedBookmarks || savedBookmarks.count == 0) {
        return;
    }
    
    NSMutableArray<NSURL *> *restoredURLs = [NSMutableArray array];
    for (NSData *bookmark in savedBookmarks) {
        NSError *error = nil;
        BOOL isStale = NO;
        NSURL *url = [NSURL URLByResolvingBookmarkData:bookmark
                                               options:NSURLBookmarkResolutionWithSecurityScope
                                         relativeToURL:nil
                                   bookmarkDataIsStale:&isStale
                                                 error:&error];
        if (url) {
            if (isStale) {
                NSLog(@"Bookmark is stale: %@", url);
            }
            
            // ⚠️ StartAccessingDecurityScopedResourse must be called to access
            BOOL accessGranted = [url startAccessingSecurityScopedResource];
            if (accessGranted) {
                [restoredURLs addObject:url];
                // Attention: It needs to be called later [url stopAccessingSecurityScopedResource]
                // Suggest storing the URL as a strong attribute and releasing it when it is dead or no longer needed
            } else {
                NSLog(@"Failed to gain security-scoped access to %@", url);
            }
        } else {
            NSLog(@"Failed to resolve bookmark: %@", error);
        }
    }
    
    if (restoredURLs.count > 0) {
        self.restoredPathArray = [restoredURLs copy]; //
        
        // Example: Display the first path
        tf_sourePath.stringValue = [restoredURLs.firstObject path];
        tf_progress.stringValue = [NSString stringWithFormat:@"The %zd files have been restored", restoredURLs.count];
    }
}

#pragma mark - NSApplicationDelegate

/**
 *  @brief Called when the application has finished launching.
 *         Initializes the converter, restores saved settings, populates OCR language buttons,
 *         and configures the window title based on build configuration.
 *  @param aNotification  The launch notification.
 */
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
    
    [self restoreBookmarkedFiles];
    [self restoreOutputDirectory];
    
    pdfConverterMutliThread = [[FPPDF2AllConverterWrapper alloc] init];
    // Display license information
    tf_license.stringValue = [NSString stringWithFormat:@"🔐 License to %s\n🕗 Expiration date: %s", FPPDF2AllConverter::GetSDKLicenseOrganization(), FPPDF2AllConverter::GetSDKLicenseExpiredDate()];
    if (FPPDF2AllConverter::isSDKLicenseAuth_ExpiredDate()) {
        tf_license.stringValue = [tf_license.stringValue stringByAppendingString:@"\n❌ License Expired"];
    }
    
    NSLog(@"NSHomeDirectory:%@", NSHomeDirectory());
    
#ifdef FP_SDK_VERSION_Dylib
    self.window.title = [self.window.title stringByAppendingString:@", Dynamic library"];
#else
    self.window.title = [self.window.title stringByAppendingString:@", Static library"];
#endif
    
    
#ifndef __OPTIMIZE__
    if(0){
        // Log Path
        NSString* logPath = [FPPDF2AllConverterWrapper DebugLogPath];
        NSLog(@"The log path: %@", logPath);
        RevealFileInFinder(logPath);
    }
    
#endif
    
    
    
#ifdef __OPTIMIZE__
    self.window.title = [self.window.title stringByAppendingString:@", Release"];
#else
    self.window.title = [self.window.title stringByAppendingString:@", Debug"];
#endif
    
    
    // Restore saved source path and password
    tf_sourePath.stringValue = [[NSUserDefaults standardUserDefaults] objectForKey:@"sourePath"];
    tf_sourePassword.stringValue = [[NSUserDefaults standardUserDefaults] objectForKey:@"sourePassword"];
    
    // Restore saved output format selection
    NSUInteger indexFormat = [[NSUserDefaults standardUserDefaults] integerForKey:@"outputFormat"];
    [pub_outputformat selectItemAtIndex:indexFormat];
    
    // Restore saved settings tab index
    NSUInteger indexSettings = [[NSUserDefaults standardUserDefaults] integerForKey:@"g_outputFormatsettings"];
    [tbv_settings selectTabViewItemAtIndex:indexSettings];
    
    // Initialize path array from saved source path
    if(tf_sourePath.stringValue){
        self.pathArray = [NSMutableArray arrayWithObjects:[NSURL fileURLWithPath:tf_sourePath.stringValue], nil];
    }
    
    // Initialize "open after conversion" setting (default: ON)
    if([[NSUserDefaults standardUserDefaults] objectForKey:@"settings_openAfterConversion"] == nil){
        [[NSUserDefaults standardUserDefaults] setInteger:1 forKey:@"settings_openAfterConversion"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    btn_openAfter.state = [[[NSUserDefaults standardUserDefaults] objectForKey:@"settings_openAfterConversion"] integerValue];
    
    // Restore page range settings
    sc_pageRange.selectedSegment = [[NSUserDefaults standardUserDefaults] integerForKey:@"settings_pageRangeSegment"];
    tf_pageRange.stringValue = [[NSUserDefaults standardUserDefaults] objectForKey:@"settings_pageRange"];
    if(sc_pageRange.selectedSegment == 4){
        tf_pageRange.enabled = YES;
    }else{
        tf_pageRange.enabled = NO;
    }
    
    // Restore multi-thread settings
    sc_multiThread.selectedSegment = [[NSUserDefaults standardUserDefaults] integerForKey:@"settings_multiThreadSegment"];
    tf_multiThread.stringValue = [[NSUserDefaults standardUserDefaults] objectForKey:@"settings_multiThread"];
    if(sc_multiThread.selectedSegment == 4){
        tf_multiThread.enabled = YES;
    }else{
        tf_multiThread.enabled = NO;
    }
    
    // Restore HTML layout mode setting
    NSUInteger html_layoutMode = [[NSUserDefaults standardUserDefaults] integerForKey:@"html_layoutMode"];
    [html_pub_layoutMode selectItemAtIndex:html_layoutMode];
    
    // Restore OCR settings
    ocr_btn_isEnableOCR.state = [[[NSUserDefaults standardUserDefaults] objectForKey:@"settings_ocr_isEnableOCR"] integerValue];
    ocr_btn_isEnableImageScan.state = [[[NSUserDefaults standardUserDefaults] objectForKey:@"settings_ocr_isEnableImageScan"] integerValue];
    if([[NSUserDefaults standardUserDefaults] objectForKey:@"settings_ocr_imageDPI"]){
        ocr_sc_imageDPI.selectedSegment = [[NSUserDefaults standardUserDefaults] integerForKey:@"settings_ocr_imageDPI"];
    }
    
    
    // Initialize OCR language buttons array
    ocrAllLanguageButtons = [NSMutableArray array].retain;
    [ocrAllLanguageButtons addObject:ocr_btn_lang_English];
    [ocrAllLanguageButtons addObject:ocr_btn_lang_German];
    [ocrAllLanguageButtons addObject:ocr_btn_lang_Japanese];
    [ocrAllLanguageButtons addObject:ocr_btn_lang_French];
    [ocrAllLanguageButtons addObject:ocr_btn_lang_Italian];
    [ocrAllLanguageButtons addObject:ocr_btn_lang_Portuguese];
    [ocrAllLanguageButtons addObject:ocr_btn_lang_Spanish];
    [ocrAllLanguageButtons addObject:ocr_btn_lang_Russian];
    [ocrAllLanguageButtons addObject:ocr_btn_lang_Korean];
    [ocrAllLanguageButtons addObject:ocr_btn_lang_Dutch];
    [ocrAllLanguageButtons addObject:ocr_btn_lang_Polish];
    [ocrAllLanguageButtons addObject:ocr_btn_lang_Swedish];
    [ocrAllLanguageButtons addObject:ocr_btn_lang_Arab];
    [ocrAllLanguageButtons addObject:ocr_btn_lang_Turkish];
    [ocrAllLanguageButtons addObject:ocr_btn_lang_Chinese_Simplified];
    [ocrAllLanguageButtons addObject:ocr_btn_lang_Chinese_Traditional];
    [ocrAllLanguageButtons addObject:ocr_btn_lang_Vietnamese];
    [ocrAllLanguageButtons addObject:ocr_btn_lang_Indonesian];
    [ocrAllLanguageButtons addObject:ocr_btn_lang_Ukrainian];
    [ocrAllLanguageButtons addObject:ocr_btn_lang_Czech];
    
    // Initialize OCR language codes array (must match the button order above)
    ocrAllLanguageCodes = [[NSMutableArray alloc] initWithObjects:
                           @"eng",        // English
                           @"deu",        // German
                           @"jpn",        // Japanese
                           @"fra",        // French
                           @"ita",        // Italian
                           @"por",        // Portuguese
                           @"spa",        // Spanish
                           @"rus",        // Russian
                           @"kor",        // Korean
                           @"nld",        // Dutch
                           @"pol",        // Polish
                           @"swe",        // Swedish
                           @"ara",        // Arab
                           @"tur",        // Turkish
                           @"chi_sim",    // Chinese Simplified
                           @"chi_tra",    // Chinese Traditional
                           @"vie",        // Vietnamese
                           @"ind",        // Indonesian
                           @"ukr",        // Ukrainian
                           @"ces",        // Czech
                           nil];
    
    // Retrieve saved OCR language string from preferences
    NSString *savedLanguages = ocr_tf_languages.stringValue;
    if([[NSUserDefaults standardUserDefaults] objectForKey:@"settings_ocr_languages"]){
        savedLanguages = [[NSUserDefaults standardUserDefaults] objectForKey:@"settings_ocr_languages"];
    }
    
    savedLanguages = [savedLanguages stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (savedLanguages && savedLanguages.length) {
        ocr_tf_languages.stringValue = savedLanguages;
        
        ocrSelectedLanguageCodes = [[NSMutableArray alloc] initWithArray:[savedLanguages componentsSeparatedByString:@"+"]];
        
        for (NSString* ocr_language in ocrSelectedLanguageCodes) {
            NSString *cleanLanguage = [ocr_language stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            if (cleanLanguage.length == 0) continue;
            
            NSInteger index = [ocrAllLanguageCodes indexOfObject:cleanLanguage];
            
            if (index != NSNotFound && index < [ocrAllLanguageButtons count]) {
                NSButton* buttonA = [ocrAllLanguageButtons objectAtIndex:index];
                [buttonA setState:NSOnState];
            }
        }
    } else {
        ocr_tf_languages.stringValue = @"";
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"settings_ocr_languages"];
        ocrSelectedLanguageCodes = [[NSMutableArray alloc] init];
    }
}


/**
 *  @brief Called when a tab view item is selected. Saves the selected tab index to preferences.
 *  @param tabView      The tab view that sent the message.
 *  @param tabViewItem  The selected tab view item.
 */
- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(nullable NSTabViewItem *)tabViewItem NS_SWIFT_UI_ACTOR
{
    NSUInteger indexSettings = [tabView indexOfTabViewItem:tabViewItem];
    [[NSUserDefaults standardUserDefaults] setInteger:indexSettings forKey:@"g_outputFormatsettings"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

/**
 *  @brief Determines whether the application should terminate when the last window is closed.
 *  @param sender  The application instance.
 *  @return YES to terminate the application when the last window is closed.
 */
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender;
{
    return YES;
}

/**
 *  @brief Called just before the application terminates.
 *         Releases security-scoped resources and persists user settings to preferences.
 *  @param notification  The termination notification.
 */
- (void)applicationWillTerminate:(NSNotification *)notification
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
    
    // Release security-scoped resource for the output directory
    if (self.outputDirectoryURL) {
        [self.outputDirectoryURL stopAccessingSecurityScopedResource];
        self.outputDirectoryURL = nil;
    }
    
    // Release security-scoped resources for all restored PDF files
    if (self.restoredPathArray) {
        for (NSURL *url in self.restoredPathArray) {
            [url stopAccessingSecurityScopedResource];
        }
    }
    
    // Persist page range setting
    if(tf_pageRange.stringValue && tf_pageRange.stringValue.length){
        [[NSUserDefaults standardUserDefaults] setObject:tf_pageRange.stringValue forKey:@"settings_pageRange"];
    }else{
        [[NSUserDefaults standardUserDefaults] setObject:@"1" forKey:@"settings_pageRange"];
    }
    
    
    // Persist multi-thread setting
    if(tf_multiThread.stringValue && tf_multiThread.stringValue.length){
        [[NSUserDefaults standardUserDefaults] setObject:tf_multiThread.stringValue forKey:@"settings_multiThread"];
    }else{
        [[NSUserDefaults standardUserDefaults] setObject:@"3" forKey:@"settings_multiThread"];
    }
    
}

#pragma mark - NSWindowDelegate

/**
 *  @brief Called when the main window is about to close. Terminates the application.
 *  @param notification  The close notification.
 */
- (void)windowWillClose:(NSNotification *)notification;
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
    [[NSApplication sharedApplication] terminate:nil];
}

#pragma mark - File & Directory Actions

/**
 *  @brief Opens a panel for the user to select the output directory.
 *         Creates a security-scoped bookmark to persist access permission across launches.
 *  @param sender  The control that triggered the action.
 */
- (IBAction)selectOutputDirectory:(id)sender {
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseFiles:NO];
    [openPanel setCanChooseDirectories:YES];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setCanCreateDirectories:YES];

    [openPanel beginSheetModalForWindow:[NSApplication sharedApplication].keyWindow
                      completionHandler:^(NSInteger result) {
        if (result == NSModalResponseOK) {
            NSURL *selectedDir = [[openPanel URLs] firstObject];
            if (selectedDir) {
                self.tf_outputPath.stringValue = [selectedDir path];

                // ✅ Create Security-Scoped Bookmark
                NSError *error = nil;
                NSData *bookmark = [selectedDir bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope
                                             includingResourceValuesForKeys:nil
                                                              relativeToURL:nil
                                                                          error:&error];
                if (bookmark) {
                    [[NSUserDefaults standardUserDefaults] setObject:bookmark forKey:@"OutputDirectoryBookmark"];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                    
                    if ([selectedDir startAccessingSecurityScopedResource]) {
                        self.outputDirectoryURL = selectedDir;
                        NSLog(@"Obtained access to the output directory: %@", selectedDir);
                    } else {
                        NSLog(@"❌ Unable to obtain output directory permission");
                        self.outputDirectoryURL = nil;
                    }
                } else {
                    NSLog(@"❌ Failed to create directory bookmark: %@", error);
                }
            }
        }
    }];
}



/**
 *  @brief Opens a file dialog for the user to select one or more PDF files.
 *         Creates security-scoped bookmarks for persistent access and updates the UI
 *         with the number of selected files and pages.
 *  @param sender  The control that triggered the action.
 */
- (IBAction)selectFile:(id)sender {
    NSLog(@"%@", NSStringFromSelector(_cmd));
    
    NSOpenPanel* openDlg = [NSOpenPanel openPanel];
    [openDlg setCanChooseFiles:YES];
    [openDlg setCanChooseDirectories:NO];
    [openDlg setAllowsMultipleSelection:YES];
    [openDlg setCanCreateDirectories:NO];
    
    [openDlg beginSheetModalForWindow:[NSApplication sharedApplication].keyWindow completionHandler:^(NSInteger result) {
        if (result == NSModalResponseOK) {
            NSArray<NSURL *> *selectedURLs = [openDlg URLs];
            NSLog(@"%@:\n%@", NSStringFromSelector(_cmd), selectedURLs);
            
            // Save the first path to the text box
            if (selectedURLs.count > 0) {
                tf_sourePath.stringValue = [[selectedURLs firstObject] path];
            }
            
            // Save original URL array (temporary)
            self.pathArray = [selectedURLs copy];
            
            // ✅ Create and save Security Copied Bookmarks
            NSMutableArray<NSData *> *bookmarks = [NSMutableArray array];
            for (NSURL *url in selectedURLs) {
                NSError *error = nil;
                NSData *bookmark = [url bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope
                                         includingResourceValuesForKeys:nil
                                                          relativeToURL:nil
                                                                      error:&error];
                if (bookmark) {
                    [bookmarks addObject:bookmark];
                } else {
                    NSLog(@"Failed to create bookmark for %@: %@", url, error);
                }
            }
            
            // Persistent saving of bookmarks (e.g. using UserDefaults)
            [[NSUserDefaults standardUserDefaults] setObject:bookmarks forKey:@"SavedPDFBookmarks"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            // Update UI
            if (selectedURLs.count > 1) {
                tf_progress.stringValue = [NSString stringWithFormat:@"You have selected %zd PDF files, you can start now!", selectedURLs.count];
            } else {
                NSURL *firstURL = selectedURLs.firstObject;
                // Attention: At this point, we already have permission to read directly
                CGPDFDocumentRef documentRef = CGPDFDocumentCreateWithURL((__bridge CFURLRef)firstURL);
                if (documentRef) {
                    NSInteger numberOfPages = CGPDFDocumentGetNumberOfPages(documentRef);
                    CGPDFDocumentRelease(documentRef);
                    tf_progress.stringValue = [NSString stringWithFormat:@"You have selected %zd PDF files, with a total of %zd pages", selectedURLs.count, numberOfPages];
                } else {
                    tf_progress.stringValue = @"Unable to open the selected PDF file";
                }
            }
        }
    }];
}


/**
 *  @brief Opens the currently selected PDF file with the default application.
 *  @param sender  The control that triggered the action.
 */
- (IBAction)openSelectedFile:(id)sender;
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
    [[NSWorkspace sharedWorkspace] openFile:tf_sourePath.stringValue];
}

/**
 *  @brief Reveals the selected PDF file in Finder.
 *  @param sender  The control that triggered the action.
 */
- (IBAction)openSelectedFileFolder:(id)sender;
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
    [[NSWorkspace sharedWorkspace] selectFile:tf_sourePath.stringValue inFileViewerRootedAtPath:[tf_sourePath.stringValue stringByDeletingLastPathComponent]];
}

/**
 *  @brief Opens the folder containing the SDK debug log file in Finder.
 *  @param sender  The control that triggered the action.
 */
- (IBAction)openLogFileFolder:(id)sender;
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
    // Retrieve the SDK debug log path
    NSString* logPath = [FPPDF2AllConverterWrapper DebugLogPath];
    NSLog(@"The log path: %@", logPath);
    
    [[NSWorkspace sharedWorkspace] selectFile:logPath inFileViewerRootedAtPath:[logPath stringByDeletingLastPathComponent]];
}

#pragma mark - Output Format & Settings Actions

/**
 *  @brief Handles output format selection via a segmented control.
 *         Switches the settings tab view and updates Excel-related control states.
 *  @param sender  The segmented control for output format selection.
 */
- (IBAction)selecteOutputFormat:(id)sender;
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
    NSSegmentedControl *button = (NSSegmentedControl*)sender;
    NSInteger sel = button.selectedSegment;
    [tbv_settings selectTabViewItemAtIndex:sel];
    
    // Enable Excel-specific options only when XLSX or CSV is selected
    xlsx_btn_allInOneSheet.enabled = (sel == 1);
    xlsx_pub_AIOStyle.enabled = xlsx_btn_allInOneSheet.enabled;
    
    [[NSUserDefaults standardUserDefaults] setInteger:sel forKey:@"outputFormat"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

/**
 *  @brief Handles output format selection via a pop-up button.
 *         Enables or disables Excel-specific options based on the selected format.
 *  @param sender  The pop-up button for output format selection.
 */
- (IBAction)selecteOutputFormat_PopUpButton:(id)sender;
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
    NSPopUpButton *button = (NSPopUpButton*)sender;
    // Enable Excel-specific options for XLSX (index 2) and CSV (index 4)
    xlsx_btn_allInOneSheet.enabled = (button.indexOfSelectedItem == 2 || button.indexOfSelectedItem == 4);
    xlsx_pub_AIOStyle.enabled = xlsx_btn_allInOneSheet.enabled;
    
    [[NSUserDefaults standardUserDefaults] setInteger:button.indexOfSelectedItem forKey:@"outputFormat"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

/**
 *  @brief Handles HTML layout mode selection from a pop-up button.
 *         Persists the selected layout mode to user preferences.
 *  @param sender  The pop-up button for HTML layout mode.
 */
- (IBAction)selectePopUpButton_HTML_LayoutMode:(id)sender
;
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
    NSPopUpButton *button = (NSPopUpButton*)sender;
    
    [[NSUserDefaults standardUserDefaults] setInteger:button.indexOfSelectedItem forKey:@"html_layoutMode"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


/**
 *  @brief Toggles the "open file after conversion" setting and persists it.
 *  @param sender  The checkbox controlling the auto-open behavior.
 */
- (IBAction)settings_openAfterConversion:(id)sender;
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
    NSButton *button = (NSButton*)sender;
    [[NSUserDefaults standardUserDefaults] setInteger:button.state forKey:@"settings_openAfterConversion"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


/**
 *  @brief Handles page range segment control changes.
 *         Enables the custom page range text field when "Custom" (segment 4) is selected.
 *  @param sender  The segmented control for page range mode.
 */
- (IBAction)settings_pageRangeSegment:(id)sender;
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
    NSSegmentedControl *button = (NSSegmentedControl*)sender;
    [[NSUserDefaults standardUserDefaults] setInteger:button.selectedSegment forKey:@"settings_pageRangeSegment"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // Enable custom page range input only when the last segment is selected
    if(button.selectedSegment == 4){
        tf_pageRange.enabled = YES;
    }else{
        tf_pageRange.enabled = NO;
    }
}

/**
 *  @brief Toggles the OCR enable/disable setting and persists it.
 *  @param sender  The checkbox for enabling/disabling OCR.
 */
- (IBAction)settings_ocr_isEnableOCR:(id)sender
;
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
    NSButton *button = (NSButton*)sender;
    [[NSUserDefaults standardUserDefaults] setInteger:button.state forKey:@"settings_ocr_isEnableOCR"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

/**
 *  @brief Toggles the OCR image scan mode setting and persists it.
 *  @param sender  The checkbox for enabling/disabling image scan mode.
 */
- (IBAction)settings_ocr_isEnableImageScan:(id)sender
;
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
    NSButton *button = (NSButton*)sender;
    [[NSUserDefaults standardUserDefaults] setInteger:button.state forKey:@"settings_ocr_isEnableImageScan"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


/**
 *  @brief Handles OCR image DPI selection and persists the choice.
 *  @param sender  The segmented control for OCR image resolution.
 */
- (IBAction)settings_ocr_imageDPI:(id)sender;
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
    NSSegmentedControl *button = (NSSegmentedControl*)sender;
    [[NSUserDefaults standardUserDefaults] setInteger:button.selectedSegment forKey:@"settings_ocr_imageDPI"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

/**
 *  @brief Handles OCR language checkbox toggling.
 *         Updates the selected language codes array, the language text field,
 *         and persists the selection to user preferences.
 *  @param sender  The language checkbox that was toggled.
 */
- (IBAction)settings_ocr_lang_checked:(id)sender

{
    NSLog(@"%@", NSStringFromSelector(_cmd));
    
    NSButton *button = (NSButton*)sender;
    
    // Find the index of the toggled button in the language buttons array
    NSInteger index = [ocrAllLanguageButtons indexOfObject:button];
    
    if (index == NSNotFound) {
        NSLog(@"Error: Button not found in ocrAllLanguageCodes array");
        return;
    }
    
    // Get the corresponding language code for this button
    NSString *languageCode = [ocrAllLanguageCodes objectAtIndex:index];
    
    // Update selected language codes: remove first to avoid duplicates, then add if checked
    [ocrSelectedLanguageCodes removeObject:languageCode];
    
    if (button.state == NSOnState) {
        [ocrSelectedLanguageCodes addObject:languageCode];
    }
    
    // Update the language text field and persist to preferences
    if (ocrSelectedLanguageCodes.count > 0) {
        NSString *resultString = [ocrSelectedLanguageCodes componentsJoinedByString:@"+"];
        ocr_tf_languages.stringValue = resultString;
        [[NSUserDefaults standardUserDefaults] setObject:resultString forKey:@"settings_ocr_languages"];
    } else {
        ocr_tf_languages.stringValue = @"";
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"settings_ocr_languages"];
    }
}

/**
 *  @brief Handles multi-thread segment control changes.
 *         Enables the custom thread count text field when "Custom" (segment 4) is selected.
 *  @param sender  The segmented control for thread count mode.
 */
- (IBAction)settings_multiThread:(id)sender;
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
    NSSegmentedControl *button = (NSSegmentedControl*)sender;
    [[NSUserDefaults standardUserDefaults] setInteger:button.selectedSegment forKey:@"settings_multiThreadSegment"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // Enable custom thread count input only when the last segment is selected
    if(button.selectedSegment == 4){
        tf_multiThread.enabled = YES;
    }else{
        tf_multiThread.enabled = NO;
    }
}

#pragma mark - PDF Conversion

/**
 *  @brief Converts a single PDF file at the given path using the current UI settings.
 *         Configures page range, thread count, output format, conversion options (Word, Excel,
 *         Image, Element, HTML, OCR), and starts the asynchronous conversion with progress callbacks.
 *  @param pdfPath  The absolute path of the PDF file to convert.
 */
- (void)convertPDFAtPath:(NSString*)pdfPath;
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
    NSString*   pdfPassword     = tf_sourePassword.stringValue;
    NSLog(@"pdfPassword: %@", pdfPassword);
    
    
    NSURL* url = [NSURL fileURLWithPath:pdfPath];
    CGPDFDocumentRef documentRef = CGPDFDocumentCreateWithURL((CFURLRef)url);
    NSInteger numberOfPages = CGPDFDocumentGetNumberOfPages(documentRef);
    CGPDFDocumentRelease(documentRef);
    // Build page index array based on the selected page range mode
    // pdfPageIndexs contains 1-based page numbers; valid range: 1 ~ numberOfPages
    NSMutableArray* pdfPageIndexs = nil;
    if(sc_pageRange.selectedSegment == 0){ // All pages
        pdfPageIndexs = [NSMutableArray array];
        for (int i = 1; i<=numberOfPages; i++) { // all pages
            [pdfPageIndexs addObject:[NSNumber numberWithUnsignedInteger:i]];
        }
    }else if(sc_pageRange.selectedSegment == 1){ // First 10 pages
        pdfPageIndexs = [NSMutableArray array];
        for (int i = 1; i<=10; i++) {
            [pdfPageIndexs addObject:[NSNumber numberWithUnsignedInteger:i]];
        }
    }else if(sc_pageRange.selectedSegment == 2){ // First 3 pages
        pdfPageIndexs = [NSMutableArray array];
        for (int i = 1; i<=3; i++) {
            [pdfPageIndexs addObject:[NSNumber numberWithUnsignedInteger:i]];
        }
    }else if(sc_pageRange.selectedSegment == 3){ // First page only
        pdfPageIndexs  = [NSMutableArray arrayWithObjects:[NSNumber numberWithUnsignedInteger:1], nil];
    }else{ // Custom page range
        pdfPageIndexs = [NSMutableArray array];
        if(tf_pageRange.stringValue && tf_pageRange.stringValue.length){
            
            // Custom Pages: 1,5,3-12
            NSArray* linePages = [tf_pageRange.stringValue componentsSeparatedByString:@","];
            
            for (NSString* linePage in linePages) {
                
                if([linePage rangeOfString:@"-"].location != NSNotFound)
                {
                    NSArray* twoValues = [linePage componentsSeparatedByString:@"-"];
                    if (twoValues.count==2) {
                        NSInteger first = [[twoValues objectAtIndex:0] integerValue];
                        NSInteger last  = [[twoValues objectAtIndex:1] integerValue];
                        
                        if (last>first) {
                            // sequence order
                            for (NSInteger value = first; value<=last; value++) {
                                if (value>0 && value<=numberOfPages) {
                                    [pdfPageIndexs addObject:[NSNumber numberWithInteger:value]];
                                }
                            }
                        }else{
                            // reverse order
                            for (NSInteger value = first; value>=last; value--) {
                                if (value>0 && value<=numberOfPages) {
                                    [pdfPageIndexs addObject:[NSNumber numberWithInteger:value]];
                                }
                            }
                            
                        }
                        
                    }
                }else {
                    NSInteger value = [linePage integerValue];
                    if (value>0 && value<=numberOfPages) {
                        [pdfPageIndexs addObject:[NSNumber numberWithInteger:value]];
                    }
                }
            }
            
            
        }else{
            
            pdfPageIndexs  = [NSMutableArray arrayWithObjects:
                              [NSNumber numberWithUnsignedInteger:1],
                              nil];
            
        }
    }
    
    // Determine the number of threads to use
    int multiThread = 0;
    if(sc_multiThread.selectedSegment > 4){
        multiThread = tf_multiThread.intValue;
    }else{
        int multiThreads[] = {0, 2, 5, 10, 20};
        multiThread = multiThreads[sc_multiThread.selectedSegment];
    }
    multiThread = MIN(multiThread, 20);
    multiThread = MAX(multiThread, 0);
    
    // Determine the output document type based on the selected format
    NSString*   destDocType = @"docx";
    static NSArray* g_outputFormats = [NSArray arrayWithObjects:@"docx", @"pptx", @"xlsx", @"---", @"csv", @"txt", @"rtf", @"html", @"---", @"image", @"element", nil].retain;
    static NSArray* g_outputFormats_folder = [NSArray arrayWithObjects:@"csv", @"htm", @"html", @"element", @"elements", @"image", @"images", @"jpg", @"jpeg", @"png", @"bmp", @"gif", @"tif", @"tiff", @"tga", @"jp2", nil].retain;
    static NSArray* g_outputFormats_images = [NSArray arrayWithObjects:@"jpeg", @"png", @"bmp", @"gif", @"tiff", @"tga", @"jp2", nil].retain;
    NSLog(@"pub_outputformat.indexOfSelectedItem: %ld", pub_outputformat.indexOfSelectedItem);
    if(pub_outputformat.indexOfSelectedItem == 9){
        destDocType   = [g_outputFormats_images objectAtIndex:image_sc_imageType.selectedSegment];
    }else{
        destDocType   = [g_outputFormats objectAtIndex:pub_outputformat.indexOfSelectedItem];
    }
    
    
    // Configure output path: use saved directory or fall back to Documents folder
    NSURL *outputDirURL = self.outputDirectoryURL;

    // Fallback to Documents if not set
    if (!outputDirURL) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        if (paths.count > 0) {
            outputDirURL = [NSURL fileURLWithPath:paths[0]];
        } else {
            NSLog(@"❌  Unable to obtain default output directory");
            tf_progress.stringValue = [NSString stringWithFormat:@"Conversion progress: Conversion has ended! %@", @" ❌  Unable to obtain default output directory"];
            return;
        }
    }

    // Build target file name
    NSString *baseName = [[pdfPath lastPathComponent] stringByDeletingPathExtension];
    NSString *filename = nil;
    if([g_outputFormats_folder containsObject:destDocType]){
        filename = [NSString stringWithFormat:@"%@_%@", baseName, destDocType];
    }else {
        filename = [NSString stringWithFormat:@"%@.%@", baseName, destDocType];
    }
    NSURL *destURL = [outputDirURL URLByAppendingPathComponent:filename];
    
    NSLog(@"destDocPath: %@", [destURL path]);
    
    [[NSFileManager defaultManager] removeItemAtURL:destURL error:nil];
    
    int imageDPI[] = {36, 72, 144, 300, 600, 1200};
    CGFloat imageQuality[] = {0.3f, 0.6f, 0.83f, 0.92f, 1.0f};
    
    
    // Configure global conversion options
    FPPDFOptions *moreOptions = new FPPDFOptions();
    moreOptions->isParserAnnots = 1;
    moreOptions->threadMax = multiThread;
    moreOptions->imageQuality = imageQuality[sc_imageQuality.indexOfSelectedItem];
    moreOptions->imageDPI     = imageDPI[sc_imageDPI.indexOfSelectedItem];
    
    // Word (DOCX) conversion options
    moreOptions->wordOptions->isMergeParagraphs                  = docx_btn_mergeParagraph.state;
    moreOptions->wordOptions->isTrimmingBlankSpaceCharacters     = docx_btn_trimBlankSpace.state;
    //moreOptions->wordOptions->outlineType                        = docx_pub_outline.indexOfSelectedItem;
    moreOptions->wordOptions->enableShapeToImage                  = docx_btn_enableShapToImage.state;
    moreOptions->wordOptions->enableMergeIntersectImages         = docx_btn_enableMergeImages.state;
    
    
    int word_imageDPI[] = {72, 144, 300, 600};
    moreOptions->imageDPI     = word_imageDPI[docx_imageDPI.indexOfSelectedItem];
    
    // Excel (XLSX/CSV) conversion options
    moreOptions->excelOptions->excelFormatOption                 = (FPPDFToExcelFormatOption)xlsx_pub_outputFormat.indexOfSelectedItem;
    moreOptions->excelOptions->thousandSeparator                  = (FPPDFToExcelthousandSeparator)xlsx_pub_ThousandSeparator.indexOfSelectedItem;
    moreOptions->excelOptions->allInOneSheet                     = xlsx_btn_allInOneSheet.state;
    moreOptions->excelOptions->allInOneSheetAddToRow                      = !xlsx_pub_AIOStyle.indexOfSelectedItem;
    moreOptions->excelOptions->overlapText                       = (FPPDFToExcelOverlapText)xlsx_pub_OverlapText.indexOfSelectedItem;
    
    moreOptions->excelOptions->recognizeNumber     = xlsx_btn_recognizeNumber.state;
    //moreOptions->excelOptions->collectCGPaths = YES;
    //moreOptions->excelOptions->collectFills = YES;
    moreOptions->excelOptions->isCSVPackageZip = xlsx_csv_btn_isPackageZip.state==NSOnState?1:0;
    
    // Image output options
    moreOptions->imageOptions->imageFormat = (FPPDF2ImageOptions_Format)image_sc_imageType.selectedSegment;
    moreOptions->imageOptions->imageQuality     = imageQuality[image_sc_imageQuality.indexOfSelectedItem];
    moreOptions->imageOptions->imageDPI     = imageDPI[image_sc_imageDPI.indexOfSelectedItem];
    //moreOptions->imageOptions->prefixName = @"Customize//\ \ image? File Name";
    moreOptions->imageOptions->isPackageZip = image_btn_isPackageZip.state?1:0;
    moreOptions->imageOptions->isAntiAlias = image_btn_isAntiAlias.state==NSOnState?true:false;
    
    // Element output options
    moreOptions->elementOptions->imageQuality     = imageQuality[element_sc_imageQuality.indexOfSelectedItem];
    //moreOptions->elementOptions->prefixName = @"Customize//\ \ image? File Name";
    moreOptions->elementOptions->isPackageZip = element_btn_isPackageZip.state==NSOnState?1:0;
    
    // HTML output options
    moreOptions->wordOptions->htmlLayoutMode     = (FPWordOption_HTML_LayoutMode)html_pub_layoutMode.indexOfSelectedItem;
    moreOptions->wordOptions->htmlMergeResource     = (FPWordOption_HTML_Merge_Resource)html_pub_mergeResource.indexOfSelectedItem;
    moreOptions->wordOptions->htmlTextFlowParagraph    = (FPWordOption_HTML_TextFlow_Paragraph)html_pub_textFlowParagraph.indexOfSelectedItem;
    moreOptions->wordOptions->htmlNavigationBar     = (FPWordOption_HTML_NavigationBar)html_pub_navigationBar.indexOfSelectedItem;
    moreOptions->wordOptions->htmlPackage     = (FPWordOption_HTML_Package)html_btn_isPackageZip.state?FPWordOption_HTML_Package_Zip:FPWordOption_HTML_Package_None;
    
    // OCR configuration
    // Language data can be obtained from https://github.com/tesseract-ocr/tessdata_best
    // tessdata_best provides high-quality but slower LSTM OCR models.
    // tessdata_fast provides faster but less accurate LSTM models.
    // tessdata supports both Tesseract 3 (legacy) and Tesseract 4 (LSTM) engines.
    moreOptions->isEnableOCR = ocr_btn_isEnableOCR.state;
    // Set OCR language codes (e.g. "eng", "chi_sim+eng")
    NSString* ocr_language = @"chi_sim+eng";
    if(ocr_tf_languages.stringValue && ocr_tf_languages.stringValue.length){
        ocr_language = ocr_tf_languages.stringValue;
    }
    snprintf(moreOptions->ocrOptions->language, sizeof(moreOptions->ocrOptions->language), "%s", ocr_language.UTF8String);
    //snprintf(moreOptions->ocrOptions->language, sizeof(moreOptions->ocrOptions->language), "chi_sim+eng"); // osd, eng, chi_sim, jpn, chi_sim+eng, script/HanS+eng
    moreOptions->ocrOptions->engineMode = FPPDFOCREngineMode_LSTM_ONLY; // FPPDFOCREngineMode_TesseractOnly, FPPDFOCREngineMode_LSTM_ONLY
    int ocr_imageDPI[] = {72, 144, 200, 300, 600};
    moreOptions->ocrOptions->resizeDPI = ocr_imageDPI[ocr_sc_imageDPI.indexOfSelectedItem];;
    moreOptions->ocrOptions->minConfidence = 10.0;
    moreOptions->ocrOptions->isEnableImageScan = ocr_btn_isEnableImageScan.state; // Enable image scan processing
    
    NSLog(@"pdfConverterMutliThread:%@", pdfConverterMutliThread);
    // Record the conversion start time for elapsed time calculation
    NSDate* conversionStartDate = [NSDate dateWithTimeIntervalSinceNow:0];
    [pdfConverterMutliThread convertPDFAtPath:pdfPath
                                     password:pdfPassword
                                  pageIndexes:pdfPageIndexs
                                 outputFormat:destDocType
                                     destPath:[destURL path]
                                  moreOptions:moreOptions
                               isInBackground:YES
                              didStartHandler:^(BOOL success, NSString *error) {
        NSLog(@"Started: %d, errorInfo: %@", success, error);
        
        tf_progress.stringValue = [NSString stringWithFormat:@"Progress: Converting to %@, page 1...", destDocType];
        //tf_progress.textColor = [NSColor colorWithDeviceRed:0.0 green:0.0 blue:1.0 alpha:1.0];
        [pi_indicator startAnimation:nil];
        
    }
                              progressHandler:^(NSInteger currentPage, NSInteger total, BOOL success, NSString *error) {
        NSLog(@"Progress: %ld/%ld", (long)currentPage, (long)total);
        tf_progress.stringValue = [NSString stringWithFormat:@"Progress: Converting to %@, %lu of %zd pages...", destDocType, currentPage, total];
    }
                              willSaveHandler:^{
        NSLog(@"Will save doc...");
        tf_progress.stringValue = [NSString stringWithFormat:@"Progress: Saving as %@...", destDocType];
        
    }
                            completionHandler:^(BOOL success, NSString *error) {
        if (success) {
            NSLog(@"✅ Conversion done! Output: %@", [destURL path]);
        } else {
            NSLog(@"❌ Failed: %@", error ?: @"Unknown error");
        }
        if (success)
        {
            // Calculate elapsed time
            NSTimeInterval conversionSpendTime = 0;
            if(conversionStartDate){
                conversionSpendTime = [[NSDate dateWithTimeIntervalSinceNow:0] timeIntervalSinceDate:conversionStartDate];
            }
            // Optionally open the output file after conversion
            if(btn_openAfter.state){
                tf_progress.stringValue = [NSString stringWithFormat:@"✅ Conversion successful! The output file will be opened, taking %0.0f seconds!", conversionSpendTime];
                [[NSWorkspace sharedWorkspace] openFile:[destURL path]];
            }else{
                tf_progress.stringValue = [NSString stringWithFormat:@"✅ Conversion successful! The output file is stored on the desktop, taking% 0.0f seconds!", conversionSpendTime];
            }
            
            //tf_progress.textColor = [NSColor colorWithDeviceRed:0.0 green:1.0 blue:0.0 alpha:1.0];
            
            //fprintf(stdout, "Conversion Spend Time: %0.0f sec\n", converter.conversionSpendTime);
            
        }else{
            NSLog(@"Error:%@", [error description]);
            tf_progress.stringValue = [NSString stringWithFormat:@"❌ Conversion failed: %@", error ?: @"Unknown error"];
        }
        
        [self loopContinueConvert];
        [pi_indicator stopAnimation:nil];
    }];
    
    // Release the conversion options object
    if(moreOptions){
        delete moreOptions;
        moreOptions = nullptr;
    }
}

/**
 *  @brief Continues converting the next PDF file in the ready queue.
 *         Called after each file conversion completes to process remaining files.
 */
- (void)loopContinueConvert
{
    if(self.readyPathArray.count){
        NSURL* url = [self.readyPathArray lastObject];
        [self.readyPathArray removeLastObject];
        [self convertPDFAtPath:[url path]];
    }
    
    
}


#pragma mark - Conversion Control Actions

/**
 *  @brief Starts the PDF conversion process.
 *         Persists current settings, initializes the conversion queue, and begins
 *         converting files one by one. Beeps and returns early if already converting.
 *  @param sender  The control that triggered the action.
 */
- (IBAction)startConvertPDF:(id)sender;
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
    
    // Persist current source path and password
    [[NSUserDefaults standardUserDefaults] setObject:tf_sourePath.stringValue forKey:@"sourePath"];
    [[NSUserDefaults standardUserDefaults] setObject:tf_sourePassword.stringValue forKey:@"sourePassword"];
    
    // Persist page range setting
    if(tf_pageRange.stringValue && tf_pageRange.stringValue.length){
        [[NSUserDefaults standardUserDefaults] setObject:tf_pageRange.stringValue forKey:@"settings_pageRange"];
    }else{
        [[NSUserDefaults standardUserDefaults] setObject:@"1" forKey:@"settings_pageRange"];
    }
    
    // Persist multi-thread setting
    if(tf_multiThread.stringValue && tf_multiThread.stringValue.length){
        [[NSUserDefaults standardUserDefaults] setObject:tf_multiThread.stringValue forKey:@"settings_multiThread"];
    }else{
        [[NSUserDefaults standardUserDefaults] setObject:@"3" forKey:@"settings_multiThread"];
    }
    
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    if(pdfConverterMutliThread.isConverting) {
        NSBeep();
        return;
    }
    
    // Initialize the conversion queue and start processing
    tf_progress.stringValue = @"";
    self.readyPathArray  = [NSMutableArray arrayWithArray:self.pathArray];
    [self loopContinueConvert];
}

/**
 *  @brief Cancels the ongoing PDF conversion.
 *  @param sender  The control that triggered the action.
 */
- (IBAction)stopConvertPDF:(id)sender;
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
    [pdfConverterMutliThread cancelConversion];
}

/**
 *  @brief Reveals the last converted output file in Finder.
 *  @param sender  The control that triggered the action.
 */
- (IBAction)openConvertedFile:(id)sender;
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
    if(pdfConverterMutliThread.destPath && [[NSFileManager defaultManager] fileExistsAtPath:pdfConverterMutliThread.destPath]){
        [[NSWorkspace sharedWorkspace] selectFile:pdfConverterMutliThread.destPath inFileViewerRootedAtPath:pdfConverterMutliThread.destPath];
    }else {
        NSLog(@"File isn't exist, %@", pdfConverterMutliThread.destPath);
    }
}

/**
 *  @brief Opens the output directory in Finder.
 *  @param sender  The control that triggered the action.
 */
- (IBAction)showOutputFolder:(id)sender;
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
    NSURL *outputDirURL = self.outputDirectoryURL;
    if(outputDirURL && [[NSFileManager defaultManager] fileExistsAtPath:outputDirURL.path]){
        [[NSWorkspace sharedWorkspace] openFile:outputDirURL.path];
    }else {
        NSLog(@"Folder isn't exist, %@", outputDirURL.path);
    }
}



@end

