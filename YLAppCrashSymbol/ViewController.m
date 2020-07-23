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
            }
        }
    }];
}

- (IBAction)didClickSymbol:(NSButton *)sender {
//    if (self.machOURL == nil) {
//        [self showAlertTitle:@"错误" message:@"请选择MachO文件！"];
//    }
//    else if (self.crashURL == nil) {
//        [self showAlertTitle:@"错误" message:@"请选择Crash日志！"];
//    }
    if (self.crashURL == nil) {
        [self showAlertTitle:@"错误" message:@"请选择Crash日志！"];
    }
    
    YLSymbolParser *parser = [[YLSymbolParser alloc] init];
    [parser parseWithMachOURL:self.machOURL error:nil];
    
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
        
        YLFunction *function = [parser getFunctionOfAddress:infos[5].longLongValue];
        NSInteger index = [textLine rangeOfString:infos[3]].location;
        NSString *symbolLine = [NSString stringWithFormat:@"%@%@", [textLine substringToIndex:index], function.name];
        if (function.name.length == 0) {
            symbolLine = [NSString stringWithFormat:@"%@(%@)", textLine, function.positionName];
        }
        [symbolTextLines addObject:symbolLine];
    }
    self.textView.string = [symbolTextLines componentsJoinedByString:@"\n"];

}

- (void)showAlertTitle:(NSString *)title message:(NSString *)msg {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"确定"];
    [alert setMessageText:title];
    [alert setInformativeText:msg];
    [alert setAlertStyle:NSAlertStyleInformational];
    [alert beginSheetModalForWindow:[NSApplication sharedApplication].keyWindow completionHandler:^(NSModalResponse returnCode) {
        
    }];
}

@end
