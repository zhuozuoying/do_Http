//
//  Do_Http_MM.h
//  DoExt_MM
//
//  Created by @userName on @time.
//  Copyright (c) 2015年 DoExt. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "doIDataSource.h"
@protocol do_Http_IMM <NSObject>
//实现同步或异步方法，parms中包含了所需用的属性
- (void)request:(NSArray *)parms;

@end