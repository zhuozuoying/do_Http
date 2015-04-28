//
//  doIAnimationModel.h
//  DoCore
//
//  Created by 刘吟 on 14/12/3.
//  Copyright (c) 2014年 DongXian. All rights reserved.
//

#import <Foundation/Foundation.h>
@class doJsonValue;
//delegate
@protocol doGetJsonCallBack
-(void) doGetJsonCallBack:(id) _jsonValue;
@end

@protocol doIDataSource
-(void) GetJsonData:(id<doGetJsonCallBack>) _callback;
@end
