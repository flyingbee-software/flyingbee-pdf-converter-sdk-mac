//
//  FPPDFFramework.h
//  FPPDFFramework
//
//  Created by James Wei on 4/2/26.
//  Copyright (c) 2026 Flyingbee Software. All rights reserved.
//

#ifndef  _FPPDFFramework_
#define  _FPPDFFramework_

#if defined(__APPLE__)
#include <FPPDFFramework/FPPDFOptions.h>
#else
#include "FPPDFOptions.h"
#endif

// === Name and version ===
#define FPPDFFramework_Name                  "FPPDFFramework"
#define FPPDFFramework_Version                "10.3.6.0" // Needs to be manually updated
// Merge compilation date and time, format: Mmm DD YYYY HH: MM: SS
extern const char* FPPDFFramework_ReleaseDate;

// Prevent C compiler from parsing C++ code
#ifdef __cplusplus

    /* ===============================    PDF Document    ==================================== */
    class FPPDFDocumentImpl;
    class FPCONVERTER_API FPPDFDocument final
    {
    public:
        FPPDFDocument(const char* fileName, const char* ownerPassword, const char* userPassword);
        FPPDFDocument(const wchar_t* fileName, const wchar_t* ownerPassword, const wchar_t* userPassword);
        ~FPPDFDocument();

        void deletePDFDocument();
        bool isOpenSuccess();

        bool isEncrypted();
        bool isHavePassword();
        int pageCount();

    private:
        FPPDFDocumentImpl* pimpl;
    };

    /* ===============================    PDF to Office Converter Delegate    ==================================== */
    class FPPDF2AllConverter;
    class FPPDF2AllConverterDelegate
    {
    public:
        // === FPPDF2AllConverter Delegate - callback function ===
        virtual void FPPDF2AllConverterDelegate_didStartConversion(FPPDF2AllConverter* converterA, bool result, char* errorInfo) { fprintf(stderr, "No inherited method yet"); }
        virtual void FPPDF2AllConverterDelegate_didEndConversion(FPPDF2AllConverter* converterA, bool result, char* errorInfo) { fprintf(stderr, "No inherited method yet"); }
        virtual void FPPDF2AllConverterDelegate_didEndPageIndex(FPPDF2AllConverter* converterA, int toPageIndexA, int toTotalPagesA, bool result, char* errorInfo) { fprintf(stderr, "No inherited method yet"); }
        virtual void FPPDF2AllConverterDelegate_willSaveDoc(FPPDF2AllConverter* converterA) { fprintf(stderr, "No inherited method yet"); }
        virtual void FPPDF2AllConverterDelegate_catchException(FPPDF2AllConverter* converterA, void* exception) { fprintf(stderr, "No inherited method yet"); }

    };

    /* ===============================    PDF to Office Converter    ==================================== */
    class FPPDF2AllConverterImpl;
    class FPCONVERTER_API FPPDF2AllConverter final
    {
    public:
        ~FPPDF2AllConverter();
        FPPDF2AllConverter();
        FPPDF2AllConverter(FPPDF2AllConverterDelegate* superDelegateA);
        
        // Has the license expired
        static bool isSDKLicenseAuth_ExpiredDate();
        static const char* GetSDKLicenseOrganization();
        static const char* GetSDKLicenseExpiredDate();
        
        // Convert PDF to Office, etc
        bool convertPDFItem(const char* strPDFFile, const char* strPassword, int* pdfPageIndexes, int pdfPageIndexesCount, const char* strOutputFormat, const char* strDestPath, FPPDFOptions* moreOptionsA, bool isInBackgroundA);

        // Convert images to PDF
        bool convertImages2PDF(const char** inputFilesArrayA, int inputFilesCount, const char* outputFilePath, bool isPaperSizeAuto, double pageWidth, double pageHeight, double pageMargins,
            FPPDFOptions_PageOrientation pageOrientation, FPPDFOptions_ScaleMethod scaleMethod, bool isCropWidth, bool isCropHeight,
                               const char* title, const char* author, const char* keywords, const char* subject, const char* creator, bool isInBackgroundA);

        // Convert Text to Word
        bool convertText2Word(const char* inputFilesArrayA, const char* outputFilePath, bool isPaperSizeAuto, double pageWidth, double pageHeight, double pageMargins, bool isOrientationLandscape, const char* fontNameA, float fontSizeA, int columnCountA, bool isInBackgroundA);

        // Cancel Conversion
        bool cancelConversion();
    private:
        FPPDF2AllConverterImpl* pimpl;
    };
#endif // Prevent C compiler from parsing C++ code
#endif
