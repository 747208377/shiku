//
//  JXMainViewController.h
//
//  Created by flyeagleTang on 14-4-3.
//  Copyright (c) 2014年 Reese. All rights reserved.
//

#import <UIKit/UIKit.h>

#ifdef Live_Version
@class JXLiveViewController;
#endif

@class JXTabMenuView;
@class JXMsgViewController;
@class JXUserViewController;
@class JXFriendViewController;
@class JXGroupViewController;
@class PSMyViewController;
@class searchUserVC;
@class WeiboViewControlle;
@class OrganizTreeViewController;
@class JXSquareViewController;


@class PSJobListVC;
@class PSAuditListVC;
@class PSWriteExamListVC;


@interface JXMainViewController : UIViewController<UIAlertViewDelegate>{
    JXTabMenuView* _tb;
    UIView* _topView;
    
    UIViewController* _selectVC;

//    JXFriendViewController* _friendVC;
    PSMyViewController* _psMyviewVC;
    WeiboViewControlle* _weiboVC;
    JXSquareViewController *_squareVC;
    JXGroupViewController* _groupVC;
//    OrganizTreeViewController *_organizVC;
    
    NSMutableArray * _friendArray;
}
//#ifdef Live_Version
//@property (strong, nonatomic) JXLiveViewController *liveVC;
//#endif
@property (strong, nonatomic) JXMsgViewController* msgVc;
@property (strong, nonatomic) JXFriendViewController* friendVC;
@property (strong, nonatomic) JXTabMenuView* tb;
@property (nonatomic, strong) UIImageView* bottomView;
@property (strong, nonatomic) UIButton* btn;
@property (strong, nonatomic) UIView* mainView;
@property (assign) BOOL IS_HR_MODE;

@property (strong, nonatomic) PSMyViewController* psMyviewVC;



-(void)onAfterLogin;

-(void)doSelected:(int)n;

@end
