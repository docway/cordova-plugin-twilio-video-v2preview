//
//  CancelAlertViewController.m
//  doclive-ui
//
//  Created by Ezequiel de Oliveira Lima on 28/11/18.
//  Copyright © 2018 Docway Aplicativo para Servicos em Saude Ltda - ME. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CancelAlertViewController.h"

@interface CancelAlertViewController ()

@end

@implementation CancelAlertView

@synthesize leaveRoomButton, resumeButton;

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];

    [self setupResumeButton];
    [self setupLeaveRoomButton];
}

- (void)setupResumeButton {
    UIBezierPath *bezierPath = [UIBezierPath bezierPathWithRoundedRect: self.resumeButton.bounds byRoundingCorners: UIRectCornerBottomRight cornerRadii: (CGSize) { 12.0, 12.0 }];
    CAShapeLayer *maskResumeButton = [CAShapeLayer layer];
    maskResumeButton.path = bezierPath.CGPath;
    self.resumeButton.layer.mask = maskResumeButton;
    
    CAShapeLayer *borderLayer = [CAShapeLayer layer];
    borderLayer.lineWidth = 2.0;
    borderLayer.path = maskResumeButton.path;
    borderLayer.fillColor = [UIColor clearColor].CGColor;
    borderLayer.strokeColor = [UIColor colorWithRed:143.0/255.0 green:209.0/255.0 blue:106.0/255.0 alpha:1.0].CGColor;
    borderLayer.frame = self.resumeButton.bounds;
    
    [resumeButton.layer addSublayer:borderLayer];
}

- (void)setupLeaveRoomButton {
    UIBezierPath *bezierPath = [UIBezierPath bezierPathWithRoundedRect: CGRectMake(0.0, 0.0, self.leaveRoomButton.bounds.size.width + 1.0, self.leaveRoomButton.bounds.size.height) byRoundingCorners: UIRectCornerBottomLeft cornerRadii: (CGSize) { 12.0, 12.0 }];
    CAShapeLayer *maskResumeButton = [CAShapeLayer layer];
    maskResumeButton.path = bezierPath.CGPath;
    self.leaveRoomButton.layer.mask = maskResumeButton;
    
    CAShapeLayer *borderLayer = [CAShapeLayer layer];
    borderLayer.lineWidth = 2.0;
    borderLayer.path = maskResumeButton.path;
    borderLayer.fillColor = [UIColor clearColor].CGColor;
    borderLayer.strokeColor = [UIColor colorWithRed:112.0/255.0 green:112.0/255.0 blue:112.0/255.0 alpha:1.0].CGColor;
    borderLayer.frame = self.leaveRoomButton.bounds;
    borderLayer.frame = CGRectMake(0.0, 0.0, self.leaveRoomButton.bounds.size.width + 1.0, self.leaveRoomButton.bounds.size.height);
    
    [leaveRoomButton.layer addSublayer:borderLayer];
}

@end

@implementation CancelAlertViewController

@synthesize delegate;


- (IBAction)touchupinFromStay:(id)sender {
    [self dismissViewControllerAnimated:true completion:nil];
}

- (IBAction)touchupinFromSignOut:(id)sender {
    if (self.delegate != nil)
        [self.delegate didCancel];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [[UIDevice currentDevice] setValue:[NSNumber numberWithInt:UIInterfaceOrientationMaskPortrait] forKey:@"orientation"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)shouldAutorotate {
    return FALSE;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end

