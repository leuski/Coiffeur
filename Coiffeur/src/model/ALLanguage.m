//
//  ALLanguage.m
//  Coiffeur
//
//  Created by Anton Leuski on 4/3/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

#import "ALLanguage.h"

#pragma clang diagnostic push
#pragma ide diagnostic ignored "OCNotLocalizedStringInspection"
static NSString* const AL_LanguagesFileName          = @"languages";
static NSString* const AL_LanguagesFileNameExtension = @"plist";
static NSString* const AL_LanguageUserDefaultsKey    = @"ALLanguage";
#pragma clang diagnostic pop

@implementation ALLanguage

+ (NSArray*)supportedLanguages
{
  static dispatch_once_t onceToken;
  static NSArray* languages;

  dispatch_once(&onceToken, ^{
    NSBundle* bundle = [NSBundle bundleForClass:[self class]];
    NSURL* url = [bundle URLForResource:AL_LanguagesFileName
                          withExtension:AL_LanguagesFileNameExtension];
    NSArray* dictionaries = [NSArray arrayWithContentsOfURL:url];
    NSMutableArray* array = [NSMutableArray new];

    for (NSDictionary* d in dictionaries) {
      [array addObject:[ALLanguage languageWithDictionary:d]];
    }

    languages = [NSArray arrayWithArray:array];
  });
  return languages;
}

+ (ALLanguage*)languageFromUserDefaults
{
  NSString*   uti
    = [[NSUserDefaults standardUserDefaults] objectForKey:AL_LanguageUserDefaultsKey];
  ALLanguage* language = [self languageWithUTI:uti];

  return language
         ? language
         : [self languageWithUTI:(__bridge NSString*)kUTTypeObjectiveCPlusPlusSource];
}

+ (instancetype)languageWithUTI:(NSString*)uti
{
  for (ALLanguage* l in[self supportedLanguages]) {
    if ([l.UTIs containsObject:uti]) {
      return l;
    }
  }

  return nil;
}

+ (instancetype)languageWithDictionary:(NSDictionary*)dictionary
{
  ALLanguage* language = [ALLanguage new];

  [language setValuesForKeysWithDictionary:dictionary];
  return language;
}

- (void)saveToUserDefaults
{
  [[NSUserDefaults standardUserDefaults] setObject:self.UTIs[0] forKey:AL_LanguageUserDefaultsKey];
}

- (NSString*)defaultExtension
{
  return [[NSWorkspace sharedWorkspace] preferredFilenameExtensionForType:self.UTIs[0]];
}

@end

