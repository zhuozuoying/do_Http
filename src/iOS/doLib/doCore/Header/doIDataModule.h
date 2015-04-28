//
//  doIAnimationModel.h
//  DoCore
//
//  Created by 刘吟 on 14/12/3.
//  Copyright (c) 2014年 DongXian. All rights reserved.
//

#import <Foundation/Foundation.h>
@class doModuleBase;

@protocol doIDataModule
-(void) BindModule:(doModuleBase*) _bindModule :(NSMutableDictionary*) _bindParas;
-(void) UnBindModule:(doModuleBase*) _bindModule;
@end
