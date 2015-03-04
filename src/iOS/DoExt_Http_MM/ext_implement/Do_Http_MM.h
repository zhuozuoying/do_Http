//
//  Do_Http_MM.h
//  DoExt_MM
//
//  Created by @userName on @time.
//  Copyright (c) 2015年 DoExt. All rights reserved.
//

#import "Do_Http_IMM.h"
#import "doMultitonModule.h"

@interface Do_Http_MM : doMultitonModule<Do_Http_IMM,NSURLConnectionDataDelegate>

@end
