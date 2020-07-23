//
//  YLSymbolParser.m
//  YLAppCrashSymbol
//
//  Created by wuyonglin on 2020/7/22.
//  Copyright © 2020 wuyonglin. All rights reserved.
//

#import "YLSymbolParser.h"
#import "CDFatFile.h"
#import "CDMachOFile.h"
#import "CDLCSegment.h"
#import "CDLCMain.h"
#import "CDLCFunctionStarts.h"
#import "CDClassDump.h"
#import "YLMethodVisitor.h"

NSString *YLSymbolParserErrorDomain = @"com.wyl.symbolparser";
NSString *YLSymbolParserErrorUserInfoKeyDesc = @"desc";

@implementation YLFunction

@end

@interface YLSymbolParser ()

@property (nonatomic, strong) NSMutableArray<YLFunction *> *functions;

@end

@implementation YLSymbolParser

- (void)parseWithMachOURL:(NSURL *)machOURL error:(NSError *__autoreleasing *)error {
    CDFile *file = [CDFile fileWithContentsOfFile:machOURL.relativePath searchPathState:nil];
    if (file == nil) {
        if (error != NULL) {
            NSDictionary *userInfo = @{YLSymbolParserErrorUserInfoKeyDesc : @"MachO文件格式错误！"};
            *error = [NSError errorWithDomain:YLSymbolParserErrorDomain code:YLSymbolParserErrorMachOFile userInfo:userInfo];
        }
        return;
    }
    if ([file isKindOfClass:[CDFatFile class]]) {
        if (error != NULL) {
            NSDictionary *userInfo = @{YLSymbolParserErrorUserInfoKeyDesc : @"不支持多架构文件，请先用lipo命名裁剪出特定架构！"};
            *error = [NSError errorWithDomain:YLSymbolParserErrorDomain code:YLSymbolParserErrorFatFile userInfo:userInfo];
        }
        return;
    }
    
    CDMachOFile *machOFile = (CDMachOFile *)file;
    CDLCSegment *text_seg = [machOFile segmentWithName:@"__TEXT"];
    CDLCMain *main_cmd = nil;
    CDLCFunctionStarts *fs_cmd = nil;
    for (CDLoadCommand *command in machOFile.loadCommands) {
        if (command.cmd == LC_MAIN){
            main_cmd = (CDLCMain *)command;
        }
        else if (command.cmd == LC_FUNCTION_STARTS){
            fs_cmd = (CDLCFunctionStarts *)command;
        }
    }
    
    if (fs_cmd == nil) {
        if (error != NULL) {
            NSDictionary *userInfo = @{YLSymbolParserErrorUserInfoKeyDesc : @"获取FUNCTION_STARTS失败！"};
            *error = [NSError errorWithDomain:YLSymbolParserErrorDomain code:YLSymbolParserErrorMachOFile userInfo:userInfo];
        }
        return;
    }
    
    CDArch targetArch;
    if ([machOFile bestMatchForLocalArch:&targetArch] == NO) {
        if (error != NULL) {
            NSDictionary *userInfo = @{YLSymbolParserErrorUserInfoKeyDesc : @"获取架构信息失败！"};
            *error = [NSError errorWithDomain:YLSymbolParserErrorDomain code:YLSymbolParserErrorMachOFile userInfo:userInfo];
        }
        return;
    }
    
    NSLog(@"Scan OC method in mach-o-file.");
    CDClassDump *classDump = [[CDClassDump alloc] init];
    classDump.targetArch = targetArch;
    NSError *classDumpError = nil;
    if (![classDump loadFile:machOFile error:&classDumpError]) {
        if (classDumpError != nil) {
            if (error != NULL) {
                NSDictionary *userInfo = @{YLSymbolParserErrorUserInfoKeyDesc : [classDumpError localizedFailureReason]};
                *error = [NSError errorWithDomain:YLSymbolParserErrorDomain code:YLSymbolParserErrorClassDump userInfo:userInfo];
            }
            return;
        }
    }
    [classDump processObjectiveCData];
    [classDump registerTypes];

    YLMethodVisitor *visitor = [[YLMethodVisitor alloc] init];
    visitor.classDump = classDump;
    [classDump recursivelyVisit:visitor];
    NSLog(@"Scan OC method finish.");
    
    NSMutableArray<YLFunction *> *functions = [[NSMutableArray alloc] init];
    NSArray *functionStarts = fs_cmd.functionStarts;
    NSUInteger vmaddr = text_seg.vmaddr;
    
    NSInteger indexOfNameNotNil = -1;
    for (int i = 0; i < functionStarts.count; i++) {
        NSNumber *addressNum = functionStarts[i];
        NSUInteger address = addressNum.unsignedIntegerValue;
        NSString *name = visitor.addressToName[@(vmaddr + address)];
        if (address == main_cmd.entryPointCommand.entryoff) {
            name = @"main";
        }
        
        YLFunction *func = [[YLFunction alloc] init];
        func.address = address;
        func.name = name;
        if (name != nil && name.length > 0) {
            indexOfNameNotNil = i;
        }
        else {
            NSString *beforeName = (indexOfNameNotNil != -1 ? functions[indexOfNameNotNil].name : @"MachO Start");
            func.positionName = [NSString stringWithFormat:@"%@ + %@ function", beforeName, @(i - indexOfNameNotNil)];
        }
        [functions addObject:func];
    }
    self.functions = functions;
}

- (YLFunction *)getFunctionOfAddress:(NSUInteger)address {
    NSInteger count = self.functions.count;
    for (int i = 0; i < count - 1; i++) {
        YLFunction *nextFunction = self.functions[i + 1];
        if (address < nextFunction.address) {
            return self.functions[i];
        }
    }
    return self.functions[count - 1];
}

@end
