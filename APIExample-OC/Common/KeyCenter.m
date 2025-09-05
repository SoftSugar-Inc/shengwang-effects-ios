//
//  KeyCenter.m
//  APIExample
//
//  Created by zhaoyongqiang on 2023/7/11.
//

#import "KeyCenter.h"

static NSString * const APPID = @"20934fa8efc94a01b88d51c6c76b9211";
static NSString * const Certificate = @"eec88ff3c26d4332af3f76f02b73c5e6";

@implementation KeyCenter

+ (nullable NSString *)AppId {
    return APPID;
}

+ (nullable NSString *)Certificate {
    return Certificate;
}

@end
