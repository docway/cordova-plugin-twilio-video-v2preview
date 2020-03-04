#import <Cordova/CDV.h>
#import "DocwayVideoViewController.h"

@interface DocwayVideoPlugin : CDVPlugin

@end

@implementation DocwayVideoPlugin

- (void)open:(CDVInvokedUrlCommand*)command {
    NSString* room = command.arguments[0];
    NSString* token = command.arguments[1];
    NSString* remoteParticipantName = command.arguments[2];
    NSString* connectionMessage = command.arguments[3];    
    
    dispatch_async(dispatch_get_main_queue(), ^{
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"DocwayVideo" bundle:nil];
        DocwayVideoViewController *vc = [sb instantiateViewControllerWithIdentifier:@"DocwayVideoViewController"];
        
        vc.accessToken = token;
        vc.remoteParticipantName = remoteParticipantName;
        vc.connectionMessage = connectionMessage;
        
        [self.viewController presentViewController:vc animated:YES completion:^{
            CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"ok"];
            [vc connectToRoom:room];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        }];
    });

}

- (void) dismissDocwayVideoController {
    [self.viewController dismissViewControllerAnimated:YES completion:nil];
}

@end
