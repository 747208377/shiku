//
//  JXLinksShareVC.m
//  shiku_im
//
//  Created by 1 on 2019/3/11.
//  Copyright © 2019年 Reese. All rights reserved.
//

#import "JXLinksShareVC.h"

#define SHARE_HEIGHT 60  // 每个单格的宽度
#define SELECTIMAGE_WIDTH SHARE_HEIGHT+30 // 每个单格的高度

@interface JXLinksShareVC ()
@property (nonatomic, strong) UIView *bigView;
@property (nonatomic, assign) CGFloat bigH;


@end

@implementation JXLinksShareVC


- (instancetype)init {
    if (self = [super init]) {
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.bigH = JX_SCREEN_BOTTOM+300;
    self.view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0];
    self.bigView = [[UIView alloc] init];
    self.bigView.frame = CGRectMake(0, JX_SCREEN_HEIGHT, JX_SCREEN_WIDTH, self.bigH);
    self.bigView.backgroundColor =  HEXCOLOR(0xE2E2E2);
    [self.view addSubview:self.bigView];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didBigView)];
    [self.bigView addGestureRecognizer:tap];

    UITapGestureRecognizer *tap1 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didView)];
    [self.view addGestureRecognizer:tap1];

    [self setupViews];
}

- (void)didBigView {
    // 点击bigview，不做处理。  优化体验， 防止每次点击到bigview 都会隐藏bigview
}

- (void)didView {
    [self hideShareView];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [UIView animateWithDuration:.3f animations:^{
        self.view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.4];
        self.bigView.frame = CGRectMake(0, JX_SCREEN_HEIGHT-self.bigH, JX_SCREEN_WIDTH, self.bigH);
    }];
}

- (void)setupViews {
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0, 10, JX_SCREEN_WIDTH, 15)];
    title.text = [NSString stringWithFormat:Localized(@"JX_ThisPageProvidedBy%@"),self.titleStr];
    title.font = SYSFONT(14);
    title.textColor = HEXCOLOR(0x666666);
    title.textAlignment = NSTextAlignmentCenter;
    [self.bigView addSubview:title];
    
    //上面的scrollview
    UIScrollView *topScrollV = [[UIScrollView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(title.frame)+20, JX_SCREEN_WIDTH, 100)];
    topScrollV.showsHorizontalScrollIndicator = NO;
    [self.bigView addSubview:topScrollV];
    
    UIView *button;
    // 图片在button中的左右间隙
    int  leftInset = (JX_SCREEN_WIDTH - SHARE_HEIGHT*5)/6+1;
    
    // 发送给朋友
    int btnX = leftInset;
    int btnY = 0;
    button = [self createButtonWithImage:@"im_linksShare_send_friend" highlight:@"im_linksShare_send_friend" target:self.delegate selector:self.onSend title:Localized(@"JXSendToFriend")];
    button.frame = CGRectMake(btnX, btnY, SHARE_HEIGHT, SELECTIMAGE_WIDTH);
    [topScrollV addSubview:button];
    
    // 分享到生活圈
    btnX += (button.frame.size.width +leftInset);
    button = [self createButtonWithImage:@"im_linksShare_life" highlight:@"im_linksShare_life" target:self.delegate selector:self.onShare title:Localized(@"JX_ShareLifeCircle")];
    button.frame = CGRectMake(btnX, btnY, SHARE_HEIGHT, SELECTIMAGE_WIDTH);
    [topScrollV addSubview:button];
    
    // 收藏
    btnX += (button.frame.size.width +leftInset);
    button = [self createButtonWithImage:@"im_linksShare_collection" highlight:@"im_linksShare_collection" target:self.delegate selector:self.onCollection title:Localized(@"JX_Collection")];
    button.frame = CGRectMake(btnX, btnY, SHARE_HEIGHT, SELECTIMAGE_WIDTH);
    [topScrollV addSubview:button];
    
    // 发送给微信好友
    btnX += (button.frame.size.width +leftInset);
    button = [self createButtonWithImage:@"im_linksShare_send_friend_WX" highlight:@"im_linksShare_send_friend_WX" target:self.delegate selector:self.onWXSend title:Localized(@"JXSendToWXFriend")];
    button.frame = CGRectMake(btnX, btnY, SHARE_HEIGHT, SELECTIMAGE_WIDTH);
    [topScrollV addSubview:button];
    
    // 分享到微信朋友圈
    btnX += (button.frame.size.width +leftInset);
    button = [self createButtonWithImage:@"im_linksShare_life_WX" highlight:@"im_linksShare_life_WX" target:self.delegate selector:self.onWXShare title:Localized(@"JX_ShareLifeWXCircle")];
    button.frame = CGRectMake(btnX, btnY, SHARE_HEIGHT, SELECTIMAGE_WIDTH);
    [topScrollV addSubview:button];
    
    // 在Safari中打开
    btnX += (button.frame.size.width +leftInset);
    button = [self createButtonWithImage:@"im_linksShare_safari" highlight:@"im_linksShare_safari" target:self.delegate selector:self.onSafari title:Localized(@"JX_OpenInSafari")];
    button.frame = CGRectMake(btnX, btnY, SHARE_HEIGHT, SELECTIMAGE_WIDTH);
    [topScrollV addSubview:button];
    
    topScrollV.contentSize = CGSizeMake(btnX+button.frame.size.width +leftInset, 0);
    
    
    /**-----------------------------------------------------------------------*/
    // 分界线
    UIView *line = [[UIView alloc] initWithFrame:CGRectMake(leftInset, CGRectGetMaxY(topScrollV.frame)+20, JX_SCREEN_WIDTH-leftInset*2, .5)];
    line.backgroundColor = HEXCOLOR(0xD6D6D6);
    [self.bigView addSubview:line];
    /**-----------------------------------------------------------------------*/
    
    
    //下面的scrollview
    UIScrollView *botScrollV = [[UIScrollView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(line.frame)+20, JX_SCREEN_WIDTH, 100)];
    botScrollV.showsHorizontalScrollIndicator = NO;
    [self.bigView addSubview:botScrollV];
    
    // 浮窗
    btnX = leftInset;
    btnY = 0;
    button = [self createButtonWithImage:self.isFloatWindow ? @"im_linksShare_un_float" : @"im_linksShare_float" highlight:self.isFloatWindow ? @"im_linksShare_un_float" : @"im_linksShare_float" target:self.delegate selector:self.onFloatWindow title:self.isFloatWindow ? [NSString stringWithFormat:@"%@%@",Localized(@"JX_Close"),Localized(@"JX_FloatingWindow")] : Localized(@"JX_FloatingWindow")];
    button.frame = CGRectMake(btnX, btnY, SHARE_HEIGHT, SELECTIMAGE_WIDTH);
    [botScrollV addSubview:button];
    
    // 投诉
    btnX += (button.frame.size.width +leftInset);
    button = [self createButtonWithImage:@"im_linksShare_complaint" highlight:@"im_linksShare_complaint" target:self.delegate selector:self.onReport title:Localized(@"UserInfoVC_Complaint")];
    button.frame = CGRectMake(btnX, btnY, SHARE_HEIGHT, SELECTIMAGE_WIDTH);
    [botScrollV addSubview:button];
    
    // 复制链接
    btnX += (button.frame.size.width +leftInset);
    button = [self createButtonWithImage:@"im_linksShare_link" highlight:@"im_linksShare_link" target:self.delegate selector:self.onPasteboard title:[NSString stringWithFormat:@"%@%@",Localized(@"JX_Copy"),Localized(@"JXLink")]];
    button.frame = CGRectMake(btnX, btnY, SHARE_HEIGHT, SELECTIMAGE_WIDTH);
    [botScrollV addSubview:button];
    // 刷新
    btnX += (button.frame.size.width +leftInset);
    button = [self createButtonWithImage:@"im_linksShare_update" highlight:@"im_linksShare_update" target:self.delegate selector:self.onUpdate title:Localized(@"JX_Refresh")];
    button.frame = CGRectMake(btnX, btnY, SHARE_HEIGHT, SELECTIMAGE_WIDTH);
    [botScrollV addSubview:button];
    // 搜索页面内容
    btnX += (button.frame.size.width +leftInset);
    button = [self createButtonWithImage:@"im_linksShare_search" highlight:@"im_linksShare_search" target:self.delegate selector:self.onSearch title:Localized(@"JX_SearchPageContent")];
    button.frame = CGRectMake(btnX, btnY, SHARE_HEIGHT, SELECTIMAGE_WIDTH);
    [botScrollV addSubview:button];
    
    // 调整字体
    btnX += (button.frame.size.width +leftInset);
    button = [self createButtonWithImage:@"im_linksShare_type" highlight:@"im_linksShare_type" target:self.delegate selector:self.onTextType title:Localized(@"JX_AdjustTheFont")];
    button.frame = CGRectMake(btnX, btnY, SHARE_HEIGHT, SELECTIMAGE_WIDTH);
    [botScrollV addSubview:button];
    
    botScrollV.contentSize = CGSizeMake(btnX+button.frame.size.width +leftInset, 0);
    
    // 取消
    UILabel *cancelLab = [[UILabel alloc] initWithFrame:CGRectMake(0, self.bigView.frame.size.height-JX_SCREEN_BOTTOM, JX_SCREEN_WIDTH, JX_SCREEN_BOTTOM)];
    cancelLab.backgroundColor = [UIColor whiteColor];
    cancelLab.text = Localized(@"JX_Cencal");
    cancelLab.textAlignment = NSTextAlignmentCenter;
    cancelLab.userInteractionEnabled = YES;
    [self.bigView addSubview:cancelLab];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideShareView)];
    [cancelLab addGestureRecognizer:tap];

}

- (UIView *)createButtonWithImage:(NSString *)normalImage
                        highlight:(NSString *)clickIamge
                           target:(id)target
                         selector:(SEL)selector
                            title:(NSString*)title
{
    UIView* v = [[UIView alloc]init];
    
    UIButton* btn = [UIFactory createButtonWithImage:normalImage highlight:clickIamge target:target selector:selector];
    btn.frame = CGRectMake(0, 0, SHARE_HEIGHT, SHARE_HEIGHT);
    [v addSubview:btn];
    
    CGSize size = [title boundingRectWithSize:CGSizeMake(SHARE_HEIGHT, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:SYSFONT(13)} context:nil].size;
    UILabel* p = [[UILabel alloc]initWithFrame:CGRectMake(0, SHARE_HEIGHT + 5, SHARE_HEIGHT, size.height)];
    p.text = title;
    p.numberOfLines = 0;
    p.font = g_factory.font13;
    p.textColor = HEXCOLOR(0x666666);
    p.textAlignment = NSTextAlignmentCenter;
    [v addSubview:p];
    return v;
}


- (void)hideShareView {
    [self hide];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
}


- (void)hide {
    [UIView animateWithDuration:.3f animations:^{
        self.bigView.frame = CGRectMake(0, JX_SCREEN_HEIGHT, JX_SCREEN_WIDTH, JX_SCREEN_HEIGHT);
        self.view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0];
    } completion:^(BOOL finished) {
        [self dismissViewControllerAnimated:YES completion:nil];
        if (self) {
            [self.view removeFromSuperview];
        }
    }];
}

@end
