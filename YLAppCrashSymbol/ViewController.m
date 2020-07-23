//
//  ViewController.m
//  YLAppCrashSymbol
//
//  Created by wuyonglin on 2020/7/22.
//  Copyright © 2020 wuyonglin. All rights reserved.
//

#import "ViewController.h"
#import "YLSymbolParser.h"

#define MACHO_BTN_TAG   1
#define CRASH_BTN_TAG   2

@interface ViewController ()

@property (weak) IBOutlet NSTextField *machOField;
@property (weak) IBOutlet NSTextField *crashField;
@property (weak) IBOutlet NSTextView *textView;

@property (nonatomic, strong) NSURL *machOURL;
@property (nonatomic, strong) NSURL *crashURL;

@property (nonatomic, strong) NSAlert *alert;

@end

@implementation ViewController

- (IBAction)didClickSelectFileButton:(NSButton *)sender {
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    openPanel.canChooseFiles = YES;
    openPanel.canChooseDirectories = NO;
    openPanel.allowsMultipleSelection = NO;
    [openPanel beginWithCompletionHandler:^(NSModalResponse result) {
        if (result == NSModalResponseOK) {
            if (sender.tag == MACHO_BTN_TAG) {
                self.machOURL = openPanel.URL;
                self.machOField.stringValue = openPanel.URL.relativePath;
            }
            else if (sender.tag == CRASH_BTN_TAG) {
                self.crashURL = openPanel.URL;
                self.crashField.stringValue = openPanel.URL.relativePath;
                NSString *crashText = [NSString stringWithContentsOfFile:self.crashURL.relativePath encoding:NSUTF8StringEncoding error:nil];
                [self showMessage:crashText];
            }
        }
    }];
}

- (IBAction)didClickSymbol:(NSButton *)sender {
    if (self.machOURL == nil) {
        [self showMessage:@"请选择MachO文件！"];
        return;
    }
    else if (self.crashURL == nil) {
        [self showMessage:@"请选择Crash日志！"];
        return;
    }
    
    sender.enabled = NO;
    [self showMessage:@"开始解析MachO文件..."];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        YLSymbolParser *parser = [[YLSymbolParser alloc] init];
        NSError *error;
        [parser parseWithMachOURL:self.machOURL error:&error];
        if (error != nil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self showAlertTitle:@"错误" message:error.userInfo[YLSymbolParserErrorUserInfoKeyDesc]];
                sender.enabled = YES;
            });
        }
        else {
            NSString *crashText = [NSString stringWithContentsOfFile:self.crashURL.relativePath encoding:NSUTF8StringEncoding error:nil];
            NSArray *crashTextLines = [crashText componentsSeparatedByString:@"\n"];
            
            NSMutableArray *symbolTextLines = [[NSMutableArray alloc] init];
            NSString *binName = nil;
            for (NSString *textLine in crashTextLines) {
                
                NSArray *components = [textLine componentsSeparatedByString:@" "];
                NSMutableArray<NSString *> *infos = [[NSMutableArray alloc] init];
                for (NSString *item in components) {
                    if (item.length > 0) {
                        [infos addObject:item];
                    }
                }
                // 获取可执行文件名
                if (infos.count > 1 && [infos[0] hasPrefix:@"Path:"]) {
                    const char *name = [infos[infos.count - 1] UTF8String];
                    const char *tmp = strrchr(name, '/');
                    if (tmp) {
                        name = tmp + 1;
                    }
                    binName = @(name);
                    [symbolTextLines addObject:textLine];
                    continue;
                }
                
                if (infos.count < 6 || ![infos[1] isEqualToString:binName] || ![infos[4] isEqualToString:@"+"]) {
                    [symbolTextLines addObject:textLine];
                    continue;
                }
                // 查询地址对应的函数名
                YLFunction *function = [parser getFunctionOfAddress:infos[5].longLongValue];
                NSInteger index = [textLine rangeOfString:infos[3]].location;
                NSString *symbolLine = [NSString stringWithFormat:@"%@%@", [textLine substringToIndex:index], function.name];
                if (function.name.length == 0) {
                    symbolLine = [NSString stringWithFormat:@"%@(%@)", textLine, function.positionName];
                }
                [symbolTextLines addObject:symbolLine];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                sender.enabled = YES;
                [self showAlertTitle:@"成功" message:@"解析完成！"];
                [self showMessage:[symbolTextLines componentsJoinedByString:@"\n"]];
            });
        }
    });
}


- (void)showMessage:(NSString *)msg {
    [self showMessage:msg appendToEnd:NO];
}

- (void)showMessage:(NSString *)msg appendToEnd:(BOOL)appendToEnd {
    NSString *text = @"";
    if (appendToEnd) {
        text = [NSString stringWithFormat:@"%@%@\n", self.textView.string, msg];
    }
    else {
        text = [NSString stringWithFormat:@"%@\n", msg];
    }
    self.textView.font = [NSFont systemFontOfSize:12];
    self.textView.string = text;
}

- (void)showAlertTitle:(NSString *)title message:(NSString *)msg {
    if (self.alert == nil) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:@"确定"];
        [alert setAlertStyle:NSAlertStyleInformational];
        self.alert = alert;
    }
    [self.alert setMessageText:title];
    [self.alert setInformativeText:msg];
    [self.alert beginSheetModalForWindow:[NSApplication sharedApplication].keyWindow completionHandler:^(NSModalResponse returnCode) {
        
    }];
}

@end
