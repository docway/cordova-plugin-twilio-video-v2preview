//
//  DocwayVideoViewController.m
//
//  Copyright © 2018 Docway, Inc. All rights reserved.
//

@import TwilioVideo;
#import "TimerController.h"
#import "CancelAlertViewController.h"
#import "DocwayVideoViewController.h"


#import <Foundation/Foundation.h>

@interface PlatformUtils : NSObject

+ (BOOL)isSimulator;

@end

@implementation PlatformUtils

+ (BOOL)isSimulator {
#if TARGET_IPHONE_SIMULATOR
    return YES;
#endif
    return NO;
}

@end

@interface DocwayVideoViewController () <TVIRemoteParticipantDelegate, TVIRoomDelegate, TVIVideoViewDelegate, TVICameraCapturerDelegate, CancelAlertViewControllerDelegate>

#pragma mark Video SDK components

@property (nonatomic, strong) TVICameraCapturer *camera;
@property (nonatomic, strong) TVILocalVideoTrack *localVideoTrack;
@property (nonatomic, strong) TVILocalAudioTrack *localAudioTrack;
@property (nonatomic, strong) TVIRemoteParticipant *participant;
@property (nonatomic, weak) TVIVideoView *remoteView;
@property (nonatomic, strong) TVIRoom *room;

#pragma mark UI Element Outlets and handles



// `TVIVideoView` created from a storyboard
@property (weak, nonatomic) IBOutlet TVIVideoView *previewView;

@property (nonatomic, weak) IBOutlet UIButton *disconnectButton;
@property (nonatomic, weak) IBOutlet UILabel *timerLabel;
@property (nonatomic, weak) IBOutlet UILabel *messageLabel;
@property (nonatomic, weak) IBOutlet UIButton *micButton;
@property (nonatomic, weak) IBOutlet UIButton *flipCameraButton;
@property (nonatomic, weak) IBOutlet UIButton *videoButton;

@end

@implementation DocwayVideoViewController

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self logMessage:[NSString stringWithFormat:@"TwilioVideo v%@", [TwilioVideo version]]];
    
    // Configure access token manually for testing, if desired! Create one manually in the console
    //  self.accessToken = @"TWILIO_ACCESS_TOKEN";
    
    
    // Preview our local camera track in the local video preview view.
    [self startPreview];
}

#pragma mark - Public

- (void)didCancel {
    [self.room disconnect];
    [self dismissViewControllerAnimated:true completion:nil];
}

- (void)connectToRoom:(NSString*)room {
    [self showRoomUI:YES];
    
    if ([self.accessToken isEqualToString:@"NO_ACCESS_TOKEN"]) {
        [self logMessage:[NSString stringWithFormat:@"Fetching an access token"]];
        [self showRoomUI:NO];
    } else {
        [self doConnect:room];
    }
}

- (IBAction)disconnectButtonPressed:(id)sender {
    CancelAlertViewController *viewController = [self.storyboard instantiateViewControllerWithIdentifier:@"Cancel"];
    viewController.delegate = self;

    [self presentViewController:viewController animated:true completion:nil];
}

- (IBAction)micButtonPressed:(id)sender {
    if (self.localAudioTrack) {
        self.localAudioTrack.enabled = !self.localAudioTrack.isEnabled;
        
        if (self.localAudioTrack.isEnabled) {
            [self.micButton setImage:[UIImage imageNamed:@"ic-microphone.png"] forState:UIControlStateNormal];
        } else {
            [self.micButton setImage:[UIImage imageNamed:@"ic-microphone-off.png"] forState:UIControlStateNormal];
        }
    }
}

- (IBAction)flipcameraButtonPressed:(id)sender {
    if(self.localVideoTrack){
        //  self.flipCameraButton.selected = !self.flipCameraButton.selected;
        //  self.flipCameraButton.alpha = self.flipCameraButton.selected ? 0.7 : 1;
        [self flipCamera];
    }
}

- (IBAction)videoButtonPressed:(id)sender {
    if(self.localVideoTrack){
        self.localVideoTrack.enabled = !self.localVideoTrack.isEnabled;
        
        if(self.localVideoTrack.isEnabled){
            [self.videoButton setImage:[UIImage imageNamed:@"ic-video.png.png"] forState:UIControlStateNormal];
        }else {
            [self.videoButton setImage:[UIImage imageNamed:@"ic-video-off.png"] forState:UIControlStateNormal];
        }
    }
}

#pragma mark - Private

- (void)startPreview {
    // TVICameraCapturer is not supported with the Simulator.
    if ([PlatformUtils isSimulator]) {
        [self.previewView removeFromSuperview];
        return;
    }
    
    self.camera = [[TVICameraCapturer alloc] initWithSource:TVICameraCaptureSourceFrontCamera delegate:self];
    self.localVideoTrack = [TVILocalVideoTrack trackWithCapturer:self.camera];
    if (!self.localVideoTrack) {
        //     [self logMessage:@"Failed to add video track"];
    } else {
        // Add renderer to video track for local preview
        [self.localVideoTrack addRenderer:self.previewView];
    }
}

- (void)flipCamera {
    if (self.camera.source == TVICameraCaptureSourceFrontCamera) {
        [self.camera selectSource:TVICameraCaptureSourceBackCameraWide];
    } else {
        [self.camera selectSource:TVICameraCaptureSourceFrontCamera];
    }
}

- (void)prepareLocalMedia {
    
    // We will share local audio and video when we connect to room.
    
    // Create an audio track.
    if (!self.localAudioTrack) {
        self.localAudioTrack = [TVILocalAudioTrack track];
        
        if (!self.localAudioTrack) {
            //         [self logMessage:@"Failed to add audio track"];
        }
    }
    
    // Create a video track which captures from the camera.
    if (!self.localVideoTrack) {
        [self startPreview];
    }
}

- (void)doConnect:(NSString*)room {
    if ([self.accessToken isEqualToString:@"NO_ACCESS_TOKEN"]) {
        //   [self logMessage:@"Please provide a valid token to connect to a room"];
        return;
    }
    // Prepare local media which we will share with Room Participants.
    [self prepareLocalMedia];
    
    TVIConnectOptions *connectOptions = [TVIConnectOptions optionsWithToken:self.accessToken
                                                                      block:^(TVIConnectOptionsBuilder * _Nonnull builder) {
                                                                          
                                                                          // Use the local media that we prepared earlier.
                                                                          builder.audioTracks = self.localAudioTrack ? @[ self.localAudioTrack ] : @[ ];
                                                                          builder.videoTracks = self.localVideoTrack ? @[ self.localVideoTrack ] : @[ ];
                                                                          
                                                                          // The name of the Room where the Client will attempt to connect to. Please note that if you pass an empty
                                                                          // Room `name`, the Client will create one for you. You can get the name or sid from any connected Room.
                                                                          builder.roomName = room;
                                                                      }];
    
    // Connect to the Room using the options we provided.
    self.room = [TwilioVideo connectWithOptions:connectOptions delegate:self];
    
    //   [self logMessage:[NSString stringWithFormat:@"Attempting to connect to room %@", room]];
}

- (void)setupRemoteView {
    // Creating `TVIVideoView` programmatically
    TVIVideoView *remoteView = [[TVIVideoView alloc] init];
    [[[TimerController alloc] initWithLabel:self.timerLabel] update];
    
    // `TVIVideoView` supports UIViewContentModeScaleToFill, UIViewContentModeScaleAspectFill and UIViewContentModeScaleAspectFit
    // UIViewContentModeScaleAspectFit is the default mode when you create `TVIVideoView` programmatically.
    self.remoteView.contentMode = UIViewContentModeScaleAspectFit;
    
    [self.view insertSubview:remoteView atIndex:0];
    self.remoteView = remoteView;
    
    NSLayoutConstraint *centerX = [NSLayoutConstraint constraintWithItem:self.remoteView
                                                               attribute:NSLayoutAttributeCenterX
                                                               relatedBy:NSLayoutRelationEqual
                                                                  toItem:self.view
                                                               attribute:NSLayoutAttributeCenterX
                                                              multiplier:1
                                                                constant:0];
    [self.view addConstraint:centerX];
    NSLayoutConstraint *centerY = [NSLayoutConstraint constraintWithItem:self.remoteView
                                                               attribute:NSLayoutAttributeCenterY
                                                               relatedBy:NSLayoutRelationEqual
                                                                  toItem:self.view
                                                               attribute:NSLayoutAttributeCenterY
                                                              multiplier:1
                                                                constant:0];
    [self.view addConstraint:centerY];
    NSLayoutConstraint *width = [NSLayoutConstraint constraintWithItem:self.remoteView
                                                             attribute:NSLayoutAttributeWidth
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:self.view
                                                             attribute:NSLayoutAttributeWidth
                                                            multiplier:1
                                                              constant:0];
    [self.view addConstraint:width];
    NSLayoutConstraint *height = [NSLayoutConstraint constraintWithItem:self.remoteView
                                                              attribute:NSLayoutAttributeHeight
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self.view
                                                              attribute:NSLayoutAttributeHeight
                                                             multiplier:1
                                                               constant:0];
    
    [self.view addConstraint:height];
}

// Reset the client ui status
- (void)showRoomUI:(BOOL)inRoom {
    // self.micButton.hidden = !inRoom;
    // self.disconnectButton.hidden = !inRoom;
    [UIApplication sharedApplication].idleTimerDisabled = inRoom;
}

- (void)cleanupRemoteParticipant {
    if (self.participant) {
        if ([self.participant.videoTracks count] > 0) {
            [self.timerLabel setText:@"00:00"];

            TVIVideoTrack *videoTrack = self.participant.videoTracks[0].videoTrack;
            [videoTrack removeRenderer:self.remoteView];
            [self.remoteView removeFromSuperview];
        }
        self.participant = nil;
    }
}

- (void)logMessage:(NSString *)msg {
    NSLog(@"%@", msg);
}

#pragma mark - TVIRoomDelegate

- (void)didConnectToRoom:(TVIRoom *)room {
    // At the moment, this example only supports rendering one Participant at a time.
    
    // [self logMessage:[NSString stringWithFormat:@"Connected to room %@ as %@", room.name, room.localParticipant.identity]];
    [self logMessage:@"Waiting on participant to join"];

    if (room.remoteParticipants.count > 0) {
        self.participant = room.remoteParticipants[0];
        self.participant.delegate = self;
        self.messageLabel.text = self.participant.identity;
    }
}

- (void)room:(TVIRoom *)room didDisconnectWithError:(nullable NSError *)error {
    // [self logMessage:[NSString stringWithFormat:@"Disconncted from room %@, error = %@", room.name, error]];
    
    [self cleanupRemoteParticipant];
    self.room = nil;
    
    [self showRoomUI:NO];
}

- (void)room:(TVIRoom *)room didFailToConnectWithError:(nonnull NSError *)error{
    //  [self logMessage:[NSString stringWithFormat:@"Failed to connect to room, error = %@", error]];
    
    self.room = nil;
    
    [self showRoomUI:NO];
}



- (void)room:(TVIRoom *)room participantDidConnect:(TVIRemoteParticipant *)participant {
    if (!self.participant) {
        self.participant = participant;
        self.participant.delegate = self;
        self.messageLabel.text = self.participant.identity;
    }
    //   [self logMessage:[NSString stringWithFormat:@"Room %@ participant %@ connected", room.name, participant.identity]];
    [self logMessage:@" "];
}

- (void)room:(TVIRoom *)room participantDidDisconnect:(TVIRemoteParticipant *)participant {
    if (self.participant == participant) {
        [self cleanupRemoteParticipant];
    }
    // [self logMessage:[NSString stringWithFormat:@"Room %@ participant %@ disconnected", room.name, participant.identity]];
    [self logMessage:@"Participant disconnected"];
    [self dismissViewControllerAnimated:true completion:nil];
}

#pragma mark - TVIRemoteParticipantDelegate

- (void)remoteParticipant:(TVIRemoteParticipant *)participant
      publishedVideoTrack:(TVIRemoteVideoTrackPublication *)publication {
    
    // Remote Participant has offered to share the video Track.
    
    [self logMessage:[NSString stringWithFormat:@"Participant %@ published %@ video track .",
                      participant.identity, publication.trackName]];
}

- (void)remoteParticipant:(TVIRemoteParticipant *)participant
    unpublishedVideoTrack:(TVIRemoteVideoTrackPublication *)publication {
    
    // Remote Participant has stopped sharing the video Track.
    
    [self logMessage:[NSString stringWithFormat:@"Participant %@ unpublished %@ video track.",
                      participant.identity, publication.trackName]];
}

- (void)remoteParticipant:(TVIRemoteParticipant *)participant
      publishedAudioTrack:(TVIRemoteAudioTrackPublication *)publication {
    
    // Remote Participant has offered to share the audio Track.
    
    [self logMessage:[NSString stringWithFormat:@"Participant %@ published %@ audio track.",
                      participant.identity, publication.trackName]];
}

- (void)remoteParticipant:(TVIRemoteParticipant *)participant
    unpublishedAudioTrack:(TVIRemoteAudioTrackPublication *)publication {
    
    // Remote Participant has stopped sharing the audio Track.
    
    [self logMessage:[NSString stringWithFormat:@"Participant %@ unpublished %@ audio track.",
                      participant.identity, publication.trackName]];
}

- (void)subscribedToVideoTrack:(TVIRemoteVideoTrack *)videoTrack
                   publication:(TVIRemoteVideoTrackPublication *)publication
                forParticipant:(TVIRemoteParticipant *)participant {
    
    // We are subscribed to the remote Participant's audio Track. We will start receiving the
    // remote Participant's video frames now.
    
    [self logMessage:[NSString stringWithFormat:@"Subscribed to %@ video track for Participant %@",
                      publication.trackName, participant.identity]];
    
    if (self.participant == participant) {
        [self setupRemoteView];
        [videoTrack addRenderer:self.remoteView];
    }
}

- (void)unsubscribedFromVideoTrack:(TVIRemoteVideoTrack *)videoTrack
                       publication:(TVIRemoteVideoTrackPublication *)publication
                    forParticipant:(TVIRemoteParticipant *)participant {
    
    // We are unsubscribed from the remote Participant's video Track. We will no longer receive the
    // remote Participant's video.
    
    [self logMessage:[NSString stringWithFormat:@"Unsubscribed from %@ video track for Participant %@",
                      publication.trackName, participant.identity]];
    
    if (self.participant == participant) {
        [videoTrack removeRenderer:self.remoteView];
        [self.remoteView removeFromSuperview];
    }
}

- (void)subscribedToAudioTrack:(TVIRemoteAudioTrack *)audioTrack
                   publication:(TVIRemoteAudioTrackPublication *)publication
                forParticipant:(TVIRemoteParticipant *)participant {
    
    // We are subscribed to the remote Participant's audio Track. We will start receiving the
    // remote Participant's audio now.
    
    [self logMessage:[NSString stringWithFormat:@"Subscribed to %@ audio track for Participant %@",
                      publication.trackName, participant.identity]];
}

- (void)unsubscribedFromAudioTrack:(TVIRemoteAudioTrack *)audioTrack
                       publication:(TVIRemoteAudioTrackPublication *)publication
                    forParticipant:(TVIRemoteParticipant *)participant {
    
    // We are unsubscribed from the remote Participant's audio Track. We will no longer receive the
    // remote Participant's audio.
    
    [self logMessage:[NSString stringWithFormat:@"Unsubscribed from %@ audio track for Participant %@",
                      publication.trackName, participant.identity]];
}

- (void)remoteParticipant:(TVIRemoteParticipant *)participant
        enabledVideoTrack:(TVIRemoteVideoTrackPublication *)publication {
    [self logMessage:[NSString stringWithFormat:@"Participant %@ enabled %@ video track.",
                      participant.identity, publication.trackName]];
}

- (void)remoteParticipant:(TVIRemoteParticipant *)participant
       disabledVideoTrack:(TVIRemoteVideoTrackPublication *)publication {
    [self logMessage:[NSString stringWithFormat:@"Participant %@ disabled %@ video track.",
                      participant.identity, publication.trackName]];
}

- (void)remoteParticipant:(TVIRemoteParticipant *)participant
        enabledAudioTrack:(TVIRemoteAudioTrackPublication *)publication {
    [self logMessage:[NSString stringWithFormat:@"Participant %@ enabled %@ audio track.",
                      participant.identity, publication.trackName]];
}

- (void)remoteParticipant:(TVIRemoteParticipant *)participant
       disabledAudioTrack:(TVIRemoteAudioTrackPublication *)publication {
    [self logMessage:[NSString stringWithFormat:@"Participant %@ disabled %@ audio track.",
                      participant.identity, publication.trackName]];
}

- (void)failedToSubscribeToAudioTrack:(TVIRemoteAudioTrackPublication *)publication
                                error:(NSError *)error
                       forParticipant:(TVIRemoteParticipant *)participant {
    [self logMessage:[NSString stringWithFormat:@"Participant %@ failed to subscribe to %@ audio track.",
                      participant.identity, publication.trackName]];
}

- (void)failedToSubscribeToVideoTrack:(TVIRemoteVideoTrackPublication *)publication
                                error:(NSError *)error
                       forParticipant:(TVIRemoteParticipant *)participant {
    [self logMessage:[NSString stringWithFormat:@"Participant %@ failed to subscribe to %@ video track.",
                      participant.identity, publication.trackName]];
}

#pragma mark - TVIVideoViewDelegate

- (void)videoView:(TVIVideoView *)view videoDimensionsDidChange:(CMVideoDimensions)dimensions {
    NSLog(@"Dimensions changed to: %d x %d", dimensions.width, dimensions.height);
    [self.view setNeedsLayout];
}

#pragma mark - TVICameraCapturerDelegate

- (void)cameraCapturer:(TVICameraCapturer *)capturer didStartWithSource:(TVICameraCaptureSource)source {
    self.previewView.mirror = (source == TVICameraCaptureSourceFrontCamera);
}

@end
