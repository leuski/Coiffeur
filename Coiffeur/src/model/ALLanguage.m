//
//  ALLanguage.m
//  Coiffeur
//
//  Created by Anton Leuski on 4/3/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

#import "ALLanguage.h"

@implementation ALLanguage

+ (NSArray*)supportedLanguages
{
  static dispatch_once_t onceToken;
	static NSArray* languages;
	dispatch_once(&onceToken, ^{
		NSArray* dictionaries = [NSArray arrayWithContentsOfURL:[[NSBundle bundleForClass:[self class]]
																			 URLForResource:@"languages" withExtension:@"plist"]];
		NSMutableArray* array = [NSMutableArray new];
		for(NSDictionary* d in dictionaries)
			[array addObject:[ALLanguage languageWithDictionary:d]];
		languages = [NSArray arrayWithArray:array];
	});
	return languages;
}

+ (ALLanguage*)languageFromUserDefaults
{
  NSString* uti = [[NSUserDefaults standardUserDefaults] objectForKey:@"ALLanguage"];
  ALLanguage* language = [self languageWithUTI:uti];
  return language ? language : [self languageWithUTI:@"public.objective-c-plus-plus-source"];
}

+ (instancetype)languageWithUTI:(NSString*)uti
{
  for(ALLanguage* l in [self supportedLanguages]) {
    if ([l.UTIs containsObject:uti])
      return l;
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
  [[NSUserDefaults standardUserDefaults] setObject:self.UTIs[0] forKey:@"ALLanguage"];
}

- (NSString*)defaultExtension
{
  return [[NSWorkspace sharedWorkspace] preferredFilenameExtensionForType:self.UTIs[0]];
}
@end
