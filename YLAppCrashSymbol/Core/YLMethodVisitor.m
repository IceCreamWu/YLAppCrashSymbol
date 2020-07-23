//
//  YLMethodVisitor.m
//  YLAppCrashSymbol
//
//  Created by wuyonglin on 2020/7/22.
//  Copyright © 2020 wuyonglin. All rights reserved.
//

#import "YLMethodVisitor.h"

#import "CDClassDump.h"
#import "CDOCProtocol.h"
#import "CDLCDylib.h"
#import "CDOCClass.h"
#import "CDOCCategory.h"
#import "CDOCClassReference.h"
#import "CDOCMethod.h"

@interface YLMethodVisitor ()

@property (nonatomic, strong) CDOCProtocol *context;

@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSString *> *addressToNameDict;

@end

@implementation YLMethodVisitor
{
    CDOCProtocol *_context;

}

- (instancetype)init {
    self = [super init];
    if (self) {
        _addressToNameDict = [[NSMutableDictionary alloc] init];
    }
    return self;
}

#pragma mark -

- (void)willVisitProtocol:(CDOCProtocol *)protocol;
{
    [self setContext:protocol];
}

- (void)willVisitClass:(CDOCClass *)aClass;
{
    [self setContext:aClass];
}


- (void)willVisitCategory:(CDOCCategory *)category;
{
    [self setContext:category];
}


- (NSString *)getCurrentClassName{
    if ([_context isKindOfClass:[CDOCClass class]]) {
        return _context.name;
    } else if([_context isKindOfClass:[CDOCCategory class]]) {
        NSString * className = [[(CDOCCategory *)_context classRef] className];
        if (!className) className = @"";
        return [NSString stringWithFormat:@"%@(%@)", className ,_context.name];
    }
    return _context.name;
}

- (void)visitClassMethod:(CDOCMethod *)method;
{
    if (method.address == 0 ) {
        return;
    }
    
    NSString *name = [NSString stringWithFormat:@"+[%@ %@]", [self getCurrentClassName], method.name];
    self.addressToNameDict[@(method.address)] = name;
    
}

- (void)visitInstanceMethod:(CDOCMethod *)method propertyState:(CDVisitorPropertyState *)propertyState;
{
    if (method.address == 0 ) {
        return;
    }
    
    NSString *name = [NSString stringWithFormat:@"-[%@ %@]", [self getCurrentClassName], method.name];
    self.addressToNameDict[@(method.address)] = name;
    
}


#pragma mark -

- (void)setContext:(CDOCProtocol *)newContext;
{
    if (newContext != _context) {
        _context = newContext;
    }
}

- (NSDictionary<NSNumber *,NSString *> *)addressToName {
    return _addressToNameDict;
}

@end
