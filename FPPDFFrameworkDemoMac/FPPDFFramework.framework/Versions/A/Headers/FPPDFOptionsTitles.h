//
//  FPPDFOptionsTitles.h
//  FPPDFFramework
//
//  Created by James Wei on 4/2/26.
//  Copyright (c) 2026 Flyingbee Software. All rights reserved.
//


#ifndef  _FPPDFOptionsTitles_
#define  _FPPDFOptionsTitles_


#ifdef __cplusplus


// HTML
extern const char* FPPDF2WordOptions_htmlLayoutMode_Titles[2];
extern const char* FPPDF2WordOptions_htmlNavigationBar_Titles[2];
extern const char* FPPDF2WordOptions_htmlMergeResource_Titles[4];
extern const char* FPPDF2WordOptions_htmlPackage_Titles[2];
extern const char* FPPDF2WordOptions_htmlTextFlowParagraph_Titles[2];


// Image
extern const char* FPPDF2ImageOptions_Format_Names[7];
extern const char* FPPDF2ImageOptions_Format_Titles[7];
extern int FPPDF2ImageOptions_Image_DPIs[11];
extern float FPPDF2ImageOptions_Image_JPEG_Qualities[5];


// FPPDFOptions
extern int FPPDFOptions_Thread_Max[10];
extern int FPPDFOptions_Element_Image_DPIs[9];
extern float FPPDFOptions_Element_Image_JPEG_Qualities[5];


// OCR
#define FPPDFOCROptions_ImageDPIs_Count 7
extern int FPPDFOCROptions_ImageDPIs[FPPDFOCROptions_ImageDPIs_Count];
extern int FPPDFOCROptions_ImageDPIs_Default;
// OCR Languages
#define FPPDFOCROptions_Languages_Count 22
extern const char* FPPDFOCROptions_Languages[FPPDFOCROptions_Languages_Count][5];
extern const char* FP_OCRLanguageMapping_Apple[FPPDFOCROptions_Languages_Count][2];

#endif
#endif

