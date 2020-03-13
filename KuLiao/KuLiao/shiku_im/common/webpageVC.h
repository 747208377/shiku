//
//  webpageVC.h
//  sjvodios
//
//  Created by  on 12-3-8.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
@class AppDelegate;
//@class admobViewController;
@protocol JXServerResult;
#import "admobViewController.h"

@interface webpageVC : admobViewController<UIWebViewDelegate,UIScrollViewDelegate>{
    UIWebView*  webView;
    UIActivityIndicatorView *aiv;

    int   _type;
    float _num;
    float _price;
    NSString* _product;
}

@property(nonatomic,strong) UIWebView* webView;
@property(nonatomic,strong) NSString* url;
@property (nonatomic, strong) NSString *titleString;
@property (nonatomic, assign) BOOL isSend;
@property (nonatomic,copy) NSString *shareParam;

-(float)getMoney:(char*)s;
@end
