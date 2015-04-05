//
//  ALDocumentController.m
//  Coiffeur
//
//  Created by Anton Leuski on 3/30/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

#import "ALDocumentController.h"
#import "AppDelegate.h"
#import "ALCoiffeurController.h"

@implementation ALDocumentController

- (void)beginOpenPanel:(NSOpenPanel*)openPanel forTypes:(NSArray*)inTypes
     completionHandler:(void (^)(NSInteger result))completionHandler
{
  openPanel.showsHiddenFiles = YES;
  [super beginOpenPanel:openPanel
               forTypes:inTypes
      completionHandler:completionHandler];
}

- (NSString*)typeForContentsOfURL:(NSURL*)url error:(NSError**)outError
{
  NSString* type = [super typeForContentsOfURL:url error:outError];

  for (Class aClass in[ALCoiffeurController availableTypes]) {
    if (![type isEqualToString:[aClass documentType]]) {
      continue;
    }

    NSString* data = [NSString stringWithContentsOfURL:url
                                              encoding:NSUTF8StringEncoding
                                                 error:outError];

    if (!data) {
      break;
    }

    for (Class c in[ALCoiffeurController availableTypes]) {
      if ([c contentsIsValidInString:data error:outError]) {
        return [c documentType];
      }
    }

    return nil;
  }

  return type;
}

- (id)openUntitledDocumentOfType:(NSString*)type
                         display:(BOOL)displayDocument
                           error:(NSError**)outError
{
  NSDocument* document = [self makeUntitledDocumentOfType:type error:outError];

  if (document) {
    [self addDocument:document];

    if (displayDocument) {
      [document makeWindowControllers];
      [document showWindows];
    }
  }

  return document;
}

@end

