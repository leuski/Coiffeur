//
//  DiffMatchPatch+ALSwiftEnum.h
//  Coiffeur
//
//  Created by Anton Leuski on 4/7/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

#import <DiffMatchPatch/DiffMatchPatch.h>

@interface Diff (ALSwiftEnum)

typedef NS_ENUM(NSUInteger, DiffOperation) {
  DiffOperationDelete,
  DiffOperationInsert,
  DiffOperationEqual
};

@property (nonatomic, assign, readonly) DiffOperation diffOperation;

@end
