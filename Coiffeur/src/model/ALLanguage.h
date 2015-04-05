//
//  ALLanguage.h
//  Coiffeur
//
//  Created by Anton Leuski on 4/3/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

@import Cocoa;

@interface ALLanguage : NSObject
@property (nonatomic, strong) NSString* uncrustifyID;
@property (nonatomic, strong) NSString* displayName;
@property (nonatomic, strong) NSString* fragariaID;
@property (nonatomic, strong) NSString* clangFormatID;
@property (nonatomic, strong) NSArray*  UTIs;
@property (nonatomic, strong, readonly) NSString* defaultExtension;

+ (NSArray*)    supportedLanguages;
+ (ALLanguage*) languageFromUserDefaults;
+ (instancetype)languageWithUTI:(NSString*)uti;

- (void)        saveToUserDefaults;
@end

