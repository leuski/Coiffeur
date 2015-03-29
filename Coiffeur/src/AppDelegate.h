//
//  AppDelegate.h
//  Coiffeur
//
//  Created by Anton Leuski on 3/25/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>

+ (NSArray*)supportedLanguages;
+ (NSString*)languageForUTI:(NSString*)uti;

@end

extern NSString * const ALDocumentStyle;
extern NSString * const ALDocumentClangFormat;
extern NSString * const ALDocumentSource;
