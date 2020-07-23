//
//  YLSymbolParser.h
//  YLAppCrashSymbol
//
//  Created by wuyonglin on 2020/7/22.
//  Copyright © 2020 wuyonglin. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *YLSymbolParserErrorDomain;
extern NSString *YLSymbolParserErrorUserInfoKeyDesc;

typedef NS_ENUM(NSInteger, YLSymbolParserErrorType) {
    YLSymbolParserErrorNone,
    YLSymbolParserErrorMachOFile,
    YLSymbolParserErrorFatFile,
    YLSymbolParserErrorClassDump,
};

@interface YLFunction : NSObject

@property (nonatomic, assign) NSUInteger address;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *positionName;

@end

@interface YLSymbolParser : NSObject

- (void)parseWithMachOURL:(NSURL *)machOURL error:(NSError **)error;

- (YLFunction *)getFunctionOfAddress:(NSUInteger)address;

@end
