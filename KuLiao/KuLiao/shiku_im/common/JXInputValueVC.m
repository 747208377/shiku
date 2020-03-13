//
//  JXInputValueVC.m
//  shiku_im
//
//  Created by flyeagleTang on 14-6-10.
//  Copyright (c) 2014年 Reese. All rights reserved.
//

#import "JXInputValueVC.h"
//#import "selectTreeVC.h"
#import "selectProvinceVC.h"
#import "selectValueVC.h"
#import "ImageResize.h"
#import "searchData.h"

#define HEIGHT 54
#define STARTTIME_TAG 1
#define IMGSIZE 100

@interface JXInputValueVC ()<UITextViewDelegate>
@property(nonatomic, assign) BOOL isShow;
@end

@implementation JXInputValueVC
@synthesize delegate,didSelect,value;

- (id)init
{
    self = [super init];
    if (self) {
        self.isGotoBack   = YES;
//        self.title = @"搜索";
        self.heightFooter = 0;
        self.heightHeader = JX_SCREEN_TOP;
        //self.view.frame = CGRectMake(0, 0, JX_SCREEN_WIDTH, JX_SCREEN_HEIGHT);
        [self createHeadAndFoot];
        self.tableBody.backgroundColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1];
        
        _name = [self createTextField:self.tableBody default:self.value hint:Localized(@"JXAlert_InputSomething")];
        _name.contentInset = UIEdgeInsetsMake(10, 10, 10, 10);
        CGRect frame = _name.frame;
        CGSize constraintSize = CGSizeMake(frame.size.width - 20, MAXFLOAT);
        CGSize size = [_name sizeThatFits:constraintSize];
        _name.frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, size.height);
        _name.delegate = self;
        [_name resignFirstResponder];

        JXLabel* p;
//        p = [self createLabel:self.tableHeader default:@"取消" selector:@selector(actionQuit)];
//        p.textColor = [UIColor whiteColor];
//        p.frame = CGRectMake(10, 20+10, 60, 25d);
        p = [self createLabel:self.tableHeader default:Localized(@"JX_Save") selector:@selector(onSave)];
        p.textColor = THESIMPLESTYLE ? [UIColor blackColor] : [UIColor whiteColor];
        p.textAlignment = NSTextAlignmentRight;
        p.frame = THE_DEVICE_HAVE_HEAD ? CGRectMake(JX_SCREEN_WIDTH -90, 20+10+23, 80, 25) : CGRectMake(JX_SCREEN_WIDTH -90, 20+10, 80, 25);
    }
    return self;
}

-(void)dealloc{
//    NSLog(@"JXInputValueVC.dealloc");
//    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    if (self.isRoomNum) {
        _name.keyboardType = UIKeyboardTypeNumberPad;
    }
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField{
    return YES;
}
//-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
//    if (self.isLimit) {
//        if (self.limitLen <= 0) {
//            self.limitLen = 15;
//        }
//        if(textField.text.length > self.limitLen && ![string isEqualToString:@""]){
//            if (!self.isShow) {
//                self.isShow = YES;
//                [g_App showAlert:Localized(@"JX_InputLimit")];
//                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//                    self.isShow = NO;
//                });
//            }
//            return NO;
//        }
//    }
//
//    return YES;
//}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    
    if ([text isEqualToString:@"\n"]) {
        [self.view endEditing:YES];
        [self onSave];
        return NO;
    }
    
    if (self.isLimit) {
        if (self.limitLen <= 0) {
            self.limitLen = 15;
        }
        if(textView.text.length > self.limitLen && ![text isEqualToString:@""]){
            if (!self.isShow) {
                self.isShow = YES;
                [g_App showAlert:Localized(@"JX_InputLimit")];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    self.isShow = NO;
                });
            }
            return NO;
        }
    }
    
    return YES;
}

- (void)textViewDidChange:(UITextView *)textView {
    
    CGRect frame = textView.frame;
    CGSize constraintSize = CGSizeMake(frame.size.width - 20, MAXFLOAT);
    CGSize size = [textView sizeThatFits:constraintSize];
    textView.frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, size.height);
}

-(UITextView*)createTextField:(UIView*)parent default:(NSString*)s hint:(NSString*)hint{
    UITextView* p = [[UITextView alloc] initWithFrame:CGRectMake(0,INSETS,JX_SCREEN_WIDTH,HEIGHT)];
    p.delegate = self;
    p.autocorrectionType = UITextAutocorrectionTypeNo;
    p.autocapitalizationType = UITextAutocapitalizationTypeNone;
    p.enablesReturnKeyAutomatically = YES;
    p.scrollEnabled = NO;
//    p.borderStyle = UITextBorderStyleNone;
    p.returnKeyType = UIReturnKeyDone;
    p.showsVerticalScrollIndicator = NO;
    p.showsHorizontalScrollIndicator = NO;
//    p.clearButtonMode = UITextFieldViewModeAlways;
    p.textAlignment = NSTextAlignmentLeft;
    p.userInteractionEnabled = YES;
    p.backgroundColor = [UIColor whiteColor];
    p.text = s;
//    p.placeholder = hint;
//    p.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 20, HEIGHT-INSETS*2)];
//    p.leftViewMode = UITextFieldViewModeAlways;
    p.font = g_factory.font16;
    [parent addSubview:p];
//    [p release];
    return p;
}

-(JXLabel*)createLabel:(UIView*)parent default:(NSString*)s selector:(SEL)selector{
    JXLabel* p = [[JXLabel alloc] initWithFrame:CGRectMake(JX_SCREEN_WIDTH/2,INSETS,JX_SCREEN_WIDTH/2 -20,HEIGHT-INSETS*2)];
    p.userInteractionEnabled = NO;
    p.text = s;
    p.font = g_factory.font14;
    p.textAlignment = NSTextAlignmentLeft;
    p.didTouch = selector;
    p.delegate = self;
    [parent addSubview:p];
//    [p release];
    return p;
}


- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self.view endEditing:YES];
    return YES;
}

-(void)onSave{
    if([_name.text isEqualToString:@""]){
        if (self.isRoomNum) {
            [g_App showAlert:Localized(@"JX_MaximumPeopleNotNull")];
        }else {
            [g_App showAlert:Localized(@"JX_NameCanNot")];
        }
        return;
    }
    self.value = _name.text;
    if (delegate && [delegate respondsToSelector:didSelect]) {
//        [delegate performSelector:didSelect withObject:self];
        [delegate performSelectorOnMainThread:didSelect withObject:self waitUntilDone:NO];
    }
    [self actionQuit];
}

@end
