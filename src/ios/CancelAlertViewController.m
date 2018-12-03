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

@end

@implementation CancelAlertViewController

@synthesize delegate;


- (IBAction)touchupinFromStay:(id)sender {
    [self dismissViewControllerAnimated:true completion:nil];
}

- (IBAction)touchupinFromSignOut:(id)sender {
    [self dismissViewControllerAnimated: true completion:^{
        if (self.delegate != nil)
            [self.delegate didCancel];
    }];
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

