//
//  Do_Http_MM.m
//  DoExt_MM
//
//  Created by @userName on @time.
//  Copyright (c) 2015年 DoExt. All rights reserved.
//

#import "do_Http_MM.h"

#import "doScriptEngineHelper.h"
#import "doIScriptEngine.h"
#import "doInvokeResult.h"

#import "doUIModuleHelper.h"
#import "doIOHelper.h"
#import "doIDataSource.h"
#import "doIPage.h"

@implementation do_Http_MM
{
    NSString *_urlStr;
    NSURLConnection *_connection;
    NSMutableData *_downData;
    doInvokeResult *_invokeResult;
    id<doGetJsonCallBack> _jsonCallBack;
}

#pragma mark - 注册属性（--属性定义--）
/*
 [self RegistProperty:[[doProperty alloc]init:@"属性名" :属性类型 :@"默认值" : BOOL:是否支持代码修改属性]];
 */
-(void)OnInit
{
    [super OnInit];
    //注册属性
    
    [self RegistProperty:[[doProperty alloc] init:@"method" :String :@"get" :NO]];
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
    _urlStr = nil;
    [_connection cancel];
    _connection = nil;
    [_downData setLength:0];
    _downData = nil;
    _invokeResult = nil;
    _jsonCallBack = nil;
}

#pragma mark -
#pragma mark - override doIDataSource
-(void) GetJsonData:(id<doGetJsonCallBack>) _callback
{
    _jsonCallBack = _callback;
    [self request];
}

#pragma mark -
#pragma mark - 同步异步方法的实现

- (void)request:(NSArray *)parms
{
    _invokeResult = [parms objectAtIndex:2];
    [self request];
}
- (void) request
{
    NSString *method = [self GetPropertyValue:@"method"];
    if(!method || [method isEqualToString:@""])
        method = [self GetProperty:@"method"].DefaultValue;
    
    NSString *urlStr = [self GetPropertyValue:@"url"];
    if(urlStr == _urlStr) return;
    
    _urlStr = urlStr;
    [_connection cancel];
    
    NSString *timeout = [self GetPropertyValue:@"timeout"];
    if(!timeout || [timeout isEqualToString:@""])
        timeout = [self GetProperty:@"timeout"].DefaultValue;
    
    NSString *contentType = [self GetPropertyValue:@"contentType"];
    if(!contentType)
        contentType = @"application/x-www-form-urlencoded";
    NSURL *url = [NSURL URLWithString:[urlStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:[timeout floatValue]/1000];
    
    if([method compare:@"get" options:NSCaseInsensitiveSearch] == NSOrderedSame)
    {
        if([urlStr hasPrefix:@"https"])
        {
            [request setValue:contentType forHTTPHeaderField:@"Content-Type"];
        }
        [request setHTTPMethod:@"GET"];
        _connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
    }
    else if([method compare:@"post" options:NSCaseInsensitiveSearch] == NSOrderedSame)
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
        _urlStr = nil;
        [NSException raise:@"do_Http" format:@"请求模式未知!"];
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
    if(_jsonCallBack!=nil){
        doJsonValue* value = [[doJsonValue alloc]init];
        [value LoadDataFromText:dataStr];
        [_jsonCallBack doGetJsonCallBack:value];
    }
    [self setNil];
}
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [_invokeResult SetError:[error description]];
    [self.EventCenter FireEvent:@"response" :_invokeResult];
    if(_jsonCallBack!=nil){
        doJsonValue* value = [[doJsonValue alloc]init];
        [value LoadDataFromText:[error description]];
        [_jsonCallBack doGetJsonCallBack:value];
    }
    [self setNil];
}

- (void)setNil;
{
    _urlStr = nil;
    _connection = nil;
    [_downData setLength:0];
    _downData = nil;
    _invokeResult = nil;
    _jsonCallBack = nil;
}

@end