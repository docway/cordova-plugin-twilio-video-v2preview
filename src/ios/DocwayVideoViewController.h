//
//  DocwayVideoViewController.h
//
//  Copyright © 2018 Docway, Inc. All rights reserved.
//

@import UIKit;

@interface DocwayVideoViewController : UIViewController

@property (nonatomic, strong) NSString *accessToken;
@property (nonatomic, strong) NSString *remoteParticipantName;

- (void)connectToRoom:(NSString*)room ;

@end
