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
#import "doJsonHelper.h"
#import "doISourceFS.h"
#import "doIDataFS.h"
#import "doIOHelper.h"
#import "doUIModuleHelper.h"

@implementation do_Http_MM
{
    NSURLConnection *_connection;
    NSMutableData *_data;
    doInvokeResult *_invokeResult;
    // upload
    NSURLConnection *_upConnection;
    NSInteger _upLong;
    
    // download
    NSURLConnection *_downConnection;
    NSString *_downFilePath;
    long long _downLong;
    NSMutableData *_downData;
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
    [_connection cancel];
    _connection = nil;
    _downData = nil;
    _invokeResult = nil;
    
    [_downConnection cancel];
    _downConnection = nil;
    _downData = nil;
    
    [_upConnection cancel];
    _upConnection = nil;
    
    //自定义的全局属性
    [super Dispose];
}

#pragma mark -
#pragma mark - 同步异步方法的实现
//upload是同步方法
- (void)upload:(NSArray *)parms {
    NSDictionary * _dicParas = [parms objectAtIndex:0];
    _invokeResult = [parms objectAtIndex:2];
    NSString *path = [doJsonHelper GetOneText:_dicParas :@"path" :nil];
    if(path && path.length>0) {
        if(_upConnection)
            [_upConnection cancel];
        path = [doIOHelper GetLocalFileFullPath:self.CurrentPage.CurrentApp : path];
        NSMutableURLRequest *request = [self getRequest];
        [request setHTTPMethod:@"POST"];
        // set Content-Type in HTTP header
        NSString* BoundaryConstant = [doUIModuleHelper stringWithUUID];
        NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", BoundaryConstant ];
        [request setValue:contentType forHTTPHeaderField: @"Content-Type"];
        
        // post body
        NSMutableData *body = [NSMutableData data];
        
        [body appendData:[[NSString stringWithFormat:@"--%@\r\n", BoundaryConstant] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; filename=\"%@\"\r\n", [path lastPathComponent]] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        NSMutableData *myRequestData=[NSMutableData dataWithContentsOfFile:path];
        [body appendData:myRequestData];
        [body appendData:[[NSString stringWithFormat:@"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
        
        
        [body appendData:[[NSString stringWithFormat:@"--%@--\r\n", BoundaryConstant] dataUsingEncoding:NSUTF8StringEncoding]];
        
        // setting the body of the post to the reqeust
        [request setHTTPBody:body];
        
        // set the content-length
        _upLong = body.length;
        NSString *postLength = [NSString stringWithFormat:@"%lu", (unsigned long)_upLong];
        [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
        _upConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
    }
}
//download是同步方法
- (void)download:(NSArray *)parms {
    NSDictionary * _dicParas = [parms objectAtIndex:0];
    _downFilePath = [doJsonHelper GetOneText:_dicParas :@"path" :nil];
    _downFilePath = [doIOHelper GetLocalFileFullPath:self.CurrentPage.CurrentApp : _downFilePath];
    if(_downFilePath && _downFilePath.length>0) {
        if(_downConnection)
            [_downConnection cancel];
        NSMutableURLRequest *request = [self getRequest];
        [request setHTTPMethod:@"GET"];
        _downConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
    }
}
//request是同步方法
- (void)request:(NSArray *)parms
{
    _invokeResult = [parms objectAtIndex:2];
    [self request];
}

#pragma mark private methed
- (doInvokeResult *)getInvokeResult:(long long)currentSize :(long long)totalSize
{
    doInvokeResult *_myInvokeResult = [[doInvokeResult alloc]init:nil];
    NSMutableDictionary *jsonNode = [[NSMutableDictionary alloc] init];
    [jsonNode setObject:[NSNumber numberWithFloat:currentSize*1.0/1024] forKey:@"currentSize" ];
    [jsonNode setObject:[NSNumber numberWithFloat:totalSize*1.0/1024] forKey:@"totalSize" ];
    [_myInvokeResult SetResultNode:jsonNode];
    return _myInvokeResult;
}
- (NSMutableURLRequest *)getRequest
{
    NSString *urlStr = [self GetPropertyValue:@"url"];
    NSString *timeout = [self GetPropertyValue:@"timeout"];
    if(!timeout || [timeout isEqualToString:@""])
        timeout = [self GetProperty:@"timeout"].DefaultValue;
    
    NSURL *url = [NSURL URLWithString:[urlStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:[timeout floatValue]/1000];
    
    NSString *contentType = [self GetPropertyValue:@"contentType"];
    if(!contentType)
        contentType = @"application/x-www-form-urlencoded";

    [request setValue:contentType forHTTPHeaderField:@"Content-Type"];
    return request;
}

- (void) request
{
    if(_connection)
       [_connection cancel];
    NSMutableURLRequest *request = [self getRequest];
    NSString *method = [self GetPropertyValue:@"method"];
    if(!method || [method isEqualToString:@""])
        method = [self GetProperty:@"method"].DefaultValue;
    if([method compare:@"get" options:NSCaseInsensitiveSearch] == NSOrderedSame)
    {
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
        [request setValue:[NSString stringWithFormat:@"%lu",( unsigned long)dataLong] forHTTPHeaderField:@"Content-Length"];
        [request setHTTPBody:myRequestData];
        _connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
    }
    else
    {
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
// connection delegate
- (void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{
    if(connection == _upConnection) {
        //NSLog(@"upload progress:%@/%@",[NSString stringWithFormat:@"%f",totalBytesWritten*1.0/1024],[NSString stringWithFormat:@"%f",_upLong*1.0/1024]);
        [self.EventCenter FireEvent:@"progress" :[self getInvokeResult:totalBytesWritten :_upLong]];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    if(connection == _downConnection) {
        if(!_downData)
            _downData = [[NSMutableData alloc] init];
        [_downData setLength:0];
        _downLong = response.expectedContentLength;
    }
    else {
        if(!_data)
            _data = [[NSMutableData alloc] init];
        [_data setLength:0];
    }
    

}
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    if(connection == _downConnection) {
        [_downData appendData:data];
        [self.EventCenter FireEvent:@"progress" :[self getInvokeResult:_downData.length :_downLong]];
    }else{
        [_data appendData:data];
    }
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
   if (connection == _downConnection) {
        [_downData writeToFile:_downFilePath atomically:YES];
        [self.EventCenter FireEvent:@"success" :[self getInvokeResult:_downLong :_downLong]];
    }else{
        NSString *dataStr = [[NSString alloc] initWithData:_data encoding:NSUTF8StringEncoding];
        NSLog(@"connectionDidFinishLoading:%@",dataStr);
        [_invokeResult SetResultText:dataStr];
        [self.EventCenter FireEvent:@"success" :_invokeResult];
    }
}
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSMutableDictionary *jsonNode = [[NSMutableDictionary alloc] init];
    [jsonNode setObject:[NSNumber numberWithInt:(int)error.code ] forKey:@"status" ];
    [jsonNode setObject:[error localizedDescription] forKey:@"message"];
    NSLog(@"didFailWithError:%@",[error localizedDescription]);
    [_invokeResult SetResultNode:jsonNode];
    [self.EventCenter FireEvent:@"fail" :_invokeResult];
}

@end