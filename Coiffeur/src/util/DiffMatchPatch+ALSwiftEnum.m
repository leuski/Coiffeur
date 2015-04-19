//
//  DiffMatchPatch+ALSwiftEnum.m
//  Coiffeur
//
//  Created by Anton Leuski on 4/7/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

#import "DiffMatchPatch+ALSwiftEnum.h"

@implementation Diff (ALSwiftEnum)

- (DiffOperation)diffOperation
{
  switch (self.operation) {
    case DIFF_DELETE: return DiffOperationDelete;
    case DIFF_INSERT: return DiffOperationInsert;
    case DIFF_EQUAL: return DiffOperationEqual;
  }
}
@end
