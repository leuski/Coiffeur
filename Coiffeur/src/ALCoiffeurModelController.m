//
//  ALCoiffeurModelController.m
//  Coiffeur
//
//  Created by Anton Leuski on 3/26/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

#import "ALCoiffeurModelController.h"
#import "NSString+commandLine.h"
#import "ALCoreData.h"

#import "ALRoot.h"
#import "ALOption.h"
#import "ALSection.h"
#import "ALNode+model.h"

static NSString * ALOptionsDocumentation = nil;
static NSString * ALDefaultValues = nil;

@implementation ALCoiffeurModelController

- (instancetype)initWithUncrustifyURL:(NSURL*)url moc:(NSManagedObjectContext*)moc
{
	self = [super init];
	if (self) {

		self.uncrustifyURL = url;
		self.managedObjectContext = moc;
		
		if (!ALOptionsDocumentation)
			ALOptionsDocumentation = [self runUncrustify:@[ @"--show-config" ] text:nil];
		
		if (![self readOptionsFromString:ALOptionsDocumentation])
			return self = nil;
		
		if (!ALDefaultValues)
			ALDefaultValues = [self runUncrustify:@[ @"--update-config" ] text:nil];
		
		if (![self readValuesFromString:ALDefaultValues])
			return self = nil;
		
	}
	return self;
}

typedef enum  {
	ALNone,
	ALSectionHeader,
	ALOptionDescription
} _ALState;

- (BOOL)readOptionsFromString:(NSString*)text
{
	NSArray* lines = [text componentsSeparatedByString:@"\n"];
	if (!lines) return NO;
	
	[self.managedObjectContext disableUndoRegistration];
	
	self.root = [ALRoot objectInContext:self.managedObjectContext];
	
	NSUInteger	count = 0, optionCount = 0, sectionCount = 0;
	_ALState state = ALNone;
	ALSection*	section;
	ALOption* option;
	
	for(__strong NSString* line in lines) {
		++count;
		if (count == 1) continue;
		line = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		
		if (![line length]) {
			state = ALNone;
			continue;
		}
		
		if ([line hasPrefix:@"#"]) {
			
			if (state != ALSectionHeader) {
				++sectionCount;
				state = ALSectionHeader;
				section = [ALSection objectInContext:self.managedObjectContext];
				section.title = @"";
				section.parent = self.root;
			}
			
			line = [[line substringFromIndex:1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
			if ([line length]) {
				if ([section.title length]) {
					section.title = [section.title stringByAppendingString:@" "];
				}
				section.title = [section.title stringByAppendingString:line];
			}
			
		} else {
			
			if (state != ALOptionDescription) {
				++optionCount;
				state = ALOptionDescription;
				option = [ALOption objectInContext:self.managedObjectContext];
				option.leaf = YES;
				option.parent = section;
				option.title = option.documentation = option.type = @"";
				
				NSUInteger c = 0;
				for(NSString* v in [line componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]) {
					++c;
					if (c == 1) {
						option.key = option.name = v;
					} else {
						if ([v isEqualToString:@"{"] || [v isEqualToString:@"}"]) {
							continue;
						}
						option.type = [option.type stringByAppendingString:[v lowercaseString]];
					}
				}
			} else {
				if ([option.title length] == 0)
					option.title = line;
				else
					option.documentation = [option.documentation stringByAppendingString:@"\n"];
				option.documentation = [option.documentation stringByAppendingString:line];
			}
		}
	}
	
	[self.managedObjectContext enableUndoRegistration];
	
	return YES;
}

- (BOOL)readValuesFromString:(NSString*)text
{
	NSArray* lines = [text componentsSeparatedByString:@"\n"];
	if (!lines) return NO;
	
	[self.managedObjectContext disableUndoRegistration];
	
	for(__strong NSString* line in lines) {
		line = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		if (![line length]) continue;
		if ([line hasPrefix:@"#"]) continue;
		NSRange comment = [line rangeOfString:@"#"];
		if (comment.location != NSNotFound) {
			line = [line substringToIndex:comment.location];
		}
		NSRange equal = [line rangeOfString:@"="];
		if (equal.location != NSNotFound) {
			line = [NSString stringWithFormat:@"%@ %@",
							[line substringToIndex:equal.location],
							[line substringFromIndex:equal.location+1]];
		}
		NSArray* tokens = [line commandLineComponents];
		if (tokens.count == 0) continue;
		if (tokens.count == 1) {
			NSLog(@"Warning: wrong number of arguments %@", line);
			continue;
		}
		
		NSString* head = tokens[0];
		if ([head isEqualToString:@"type"]) {
			
		} else if ([head isEqualToString:@"define"]) {
			
		} else if ([head isEqualToString:@"macro-open"]) {
			
		} else if ([head isEqualToString:@"macro-close"]) {
			
		} else if ([head isEqualToString:@"macro-else"]) {
			
		} else if ([head isEqualToString:@"set"]) {
			
		} else if ([head isEqualToString:@"include"]) {
			
		} else if ([head isEqualToString:@"file_ext"]) {
			
		} else {
			ALOption* option = [ALOption firstObjectInContext:self.managedObjectContext
																			matchingPredicate:[NSPredicate predicateWithFormat:@"key = %@", head]
																									error:nil];
			if (option) {
				option.value = tokens[1];
			} else {
				NSLog(@"Warning: unknown token %@ on line %@", head, line);
			}
		}
	}
	
	[self.managedObjectContext enableUndoRegistration];
	
	return YES;
}

- (BOOL)writeValuesToURL:(NSURL *)absoluteURL error:(NSError **)error
{
	NSMutableString*	data = [NSMutableString new];
	for(ALOption* option in [[ALOption allObjectsInContext:self.managedObjectContext] sortedArrayUsingComparator:^NSComparisonResult(ALOption* obj1, ALOption* obj2) {
		return [obj1.key compare:obj2.key];
	}]) {
		if (!option.value) continue;
		if ([option.type isEqualToString:@"string"]) {
			[data appendFormat:@"%@ = \"%@\"\n", option.key, option.value];
		} else {
			[data appendFormat:@"%@ = %@\n", option.key, option.value];
		}
	};
	
	return [data writeToURL:absoluteURL atomically:YES encoding:NSUTF8StringEncoding error:error];
}

- (NSFileHandle*)startUncrustify:(NSArray*)args text:(NSString*)input
{
	NSURL* executableURL = self.uncrustifyURL; // [[NSBundle mainBundle] URLForAuxiliaryExecutable:@"uncrustify"];
	
	@try {
		NSTask* theTask = [[NSTask alloc] init];
		
		NSPipe* outPipe = [NSPipe pipe];
		NSFileHandle* readHandle = [outPipe fileHandleForReading];
		
		NSPipe* inpPipe = [NSPipe pipe];
		NSFileHandle* writeHandle = input ? [inpPipe fileHandleForWriting] : nil;
		
		[theTask setStandardOutput:outPipe];
		[theTask setStandardInput:inpPipe];
		[theTask setLaunchPath:executableURL.path];
		[theTask setArguments:args];
		[theTask launch];
		
		if (writeHandle) {
			[writeHandle writeData:[input dataUsingEncoding:NSUTF8StringEncoding]];
			[writeHandle closeFile];
		}
		
		return readHandle;
		
	} @catch (NSException* ex) {
		NSLog(@"%@", ex);
		return nil;
	}
}

- (BOOL)runUncrustify:(NSArray*)args text:(NSString*)input completionBlock:(void (^)(NSString*)) block
{
	NSFileHandle* readHandle = [self startUncrustify:args text:input];
	if (!readHandle) return NO;
	
	dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{ @autoreleasepool {
		NSData* data = [readHandle readDataToEndOfFile];
		NSString* text = [[NSString alloc] initWithData:data
																					 encoding:NSUTF8StringEncoding];
		dispatch_async(dispatch_get_main_queue(), ^{ @autoreleasepool {
			block(text);
		}});
	}});
	
	return YES;
}

- (NSString*)runUncrustify:(NSArray*)args text:(NSString*)input
{
	NSFileHandle* readHandle = [self startUncrustify:args text:input];
	if (!readHandle) return nil;
	
	NSData* data = [readHandle readDataToEndOfFile];
	return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

- (BOOL)uncrustify:(NSString*)input completionBlock:(void (^)(NSString*)) block
{
	NSString* configPath = [NSTemporaryDirectory() stringByAppendingPathComponent:[[NSUUID UUID] UUIDString]];
	
	NSError* error;
	if (![self writeValuesToURL:[NSURL fileURLWithPath:configPath] error:&error]) {
		NSLog(@"%@", error);
		return NO;
	}
	
	BOOL result = [self runUncrustify:@[ @"-q", @"-c", configPath ]
															 text:input
										completionBlock:^(NSString* text) {
		[[NSFileManager defaultManager] removeItemAtPath:configPath error:nil];
		block(text);
	}];
	
	if (!result) {
		[[NSFileManager defaultManager] removeItemAtPath:configPath error:nil];
	}
	
	return result;
}

@end
