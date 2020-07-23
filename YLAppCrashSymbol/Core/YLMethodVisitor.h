//
//  YLMethodVisitor.h
//  YLAppCrashSymbol
//
//  Created by wuyonglin on 2020/7/22.
//  Copyright © 2020 wuyonglin. All rights reserved.
//

#import "CDVisitor.h"

@interface YLMethodVisitor : CDVisitor

@property (nonatomic, strong, readonly) NSDictionary<NSNumber *, NSString *> *addressToName;

@end
