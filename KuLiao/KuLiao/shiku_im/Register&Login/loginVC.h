//
//  loginVC.h
//  shiku_im
//
//  Created by flyeagleTang on 14-6-7.
//  Copyright (c) 2014年 Reese. All rights reserved.
//

#import "admobViewController.h"

@interface loginVC : admobViewController{
    UITextField* _pwd;
    UITextField* _phone;
    JXUserObject* _user;
}
@property(assign)BOOL isAutoLogin;
@property(assign)BOOL isSwitchUser;
@property (nonatomic, strong) UIImageView *launchImageView;
@property (nonatomic, strong) UIButton *btn;
@property (nonatomic, strong) JXLocation *location;

@property (nonatomic, assign) BOOL isThirdLogin;
@property (nonatomic, assign) BOOL isSMSLogin;

@end
