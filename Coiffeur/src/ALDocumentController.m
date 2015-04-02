//
//  ALDocumentController.m
//  Coiffeur
//
//  Created by Anton Leuski on 3/30/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

#import "ALDocumentController.h"
#import "AppDelegate.h"
#import "Document.h"

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
	
	if ([type isEqualToString:ALDocumentClangFormatStyle] ||
			[type isEqualToString:ALDocumentUncrustifyStyle]) {
		NSString* data = [NSString stringWithContentsOfURL:url
																							encoding:NSUTF8StringEncoding
																								 error:outError];
		if (data) {
			if ([ALClangFormatDocument contentsIsValidInString:data error:outError])
				return ALDocumentClangFormatStyle;
			if ([ALUncrustifyDocument contentsIsValidInString:data error:outError])
				return ALDocumentUncrustifyStyle;
			
			return nil;
		}
	}
	
	return type;
}

@end
