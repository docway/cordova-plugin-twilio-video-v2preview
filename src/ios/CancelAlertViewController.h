#import <UIKit/UIKit.h>

@protocol CancelAlertViewControllerDelegate <NSObject>

-(void) didCancel;

@end

@interface CancelAlertView : UIView

@property (nonatomic, weak) IBOutlet UIButton *resumeButton;
@property (nonatomic, weak) IBOutlet UIButton *leaveRoomButton;

@end

@interface CancelAlertViewController : UIViewController

@property (nonatomic, weak) IBOutlet CancelAlertView *cancelAlertView;
@property (nonatomic, weak) id <CancelAlertViewControllerDelegate> delegate;

@end

