//
//  ViewController.m
//  YLAppCrashSymbol
//
//  Created by wuyonglin on 2020/7/22.
//  Copyright © 2020 wuyonglin. All rights reserved.
//

#import "ViewController.h"

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
    if (self.machOURL == nil) {
        [self showAlertTitle:@"错误" message:@"请选择MachO文件！"];
    }
    else if (self.crashURL == nil) {
        [self showAlertTitle:@"错误" message:@"请选择Crash日志！"];
    }
    
    NSMutableString *str = [[NSMutableString alloc] init];
    for (int i = 0; i < 100; i++) {
        [str appendString:@"测试测试测试TestTest\n"];
    }
    self.textView.string = str;
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
