//
//  Do_Http_MM.m
//  DoExt_MM
//
//  Created by @userName on @time.
//  Copyright (c) 2015年 DoExt. All rights reserved.
//

#import "Do_Http_MM.h"

#import "doScriptEngineHelper.h"
#import "doIScriptEngine.h"
#import "doInvokeResult.h"

#import "doUIModuleHelper.h"
#import "doIOHelper.h"


@implementation Do_Http_MM
{
    
    NSString *_url;
    NSURLConnection *_connection;
    NSMutableData *_downData;
    doInvokeResult *_invokeResult;
    
}

#pragma mark - 注册属性（--属性定义--）
/*
 [self RegistProperty:[[doProperty alloc]init:@"属性名" :属性类型 :@"默认值" : BOOL:是否支持代码修改属性]];
 */
-(void)OnInit
{
    [super OnInit];
    //注册属性
    
    [self RegistProperty:[[doProperty alloc] init:@"method" :String :@"" :NO]];
    [self RegistProperty:[[doProperty alloc] init:@"url" :String :@"" :NO]];
    [self RegistProperty:[[doProperty alloc] init:@"timeout" :Number :@"5000" :NO]];
    [self RegistProperty:[[doProperty alloc] init:@"contentType" :String :@"text/html" :NO]];
    [self RegistProperty:[[doProperty alloc] init:@"body" :String :@"" :NO]];
}

//销毁所有的全局对象
-(void)Dispose
{
    //自定义的全局属性
    [super Dispose];
    _url = nil;
    [_connection cancel];
    _connection = nil;
    [_downData setLength:0];
    _downData = nil;
    _invokeResult = nil;
}
#pragma mark -
#pragma mark - 同步异步方法的实现

 - (void)request:(NSArray *)parms
 {
     _invokeResult = [parms objectAtIndex:2];
     
     NSString *method = [self GetPropertyValue:@"method"];
     NSString *url = [self GetPropertyValue:@"url"];
     
     if(url == _url) return;
     _url = url;
     [_connection cancel];
     
     NSString *timeout = [self GetPropertyValue:@"timeout"];
     
     NSString *contentType = [self GetPropertyValue:@"contentType"];
     if(!contentType)
         contentType = @"application/x-www-form-urlencoded";
     NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:[timeout floatValue]/1000];
     if([method isEqualToString:@"get"])
     {
         if([url hasPrefix:@"https"])
         {
             [request setValue:contentType forHTTPHeaderField:@"Content-Type"];
         }
         [request setHTTPMethod:@"GET"];
         _connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
     }
     else if([method isEqualToString:@"post"])
     {
         NSString *body = [self GetPropertyValue:@"body"];
         [request setHTTPMethod:@"POST"];
         NSMutableData *myRequestData=[NSMutableData data];
         [myRequestData appendData:[body dataUsingEncoding:NSUTF8StringEncoding]];
         NSUInteger dataLong = myRequestData.length;
         [request setValue:contentType forHTTPHeaderField:@"Content-Type"];
         [request setValue:[NSString stringWithFormat:@"%lu",( unsigned long)dataLong] forHTTPHeaderField:@"Content-Length"];
         [request setHTTPBody:myRequestData];
         _connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
     }
     else
     {
         NSLog(@"请求模式未知!");
     }

 }
#pragma mark - connection

//设置证书,在客户端默认忽略证书认证
- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace
{
    return [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust];
}
- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        [[challenge sender] useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
    }
}
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    if(!_downData)
        _downData = [[NSMutableData alloc] init];
    [_downData setLength:0];
}
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [_downData appendData:data];
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSString *dataStr = [[NSString alloc] initWithData:_downData encoding:NSUTF8StringEncoding];
    
    [_invokeResult SetResultText:dataStr];
    [self.EventCenter FireEvent:@"response" :_invokeResult];
    
    [self setNil];
}
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [_invokeResult SetError:[error description]];
    [self.EventCenter FireEvent:@"response" :_invokeResult];
    
    [self setNil];
}

- (void)setNil;
{
    _url = nil;
    _connection = nil;
    [_downData setLength:0];
    _downData = nil;
    _invokeResult = nil;
}


@end