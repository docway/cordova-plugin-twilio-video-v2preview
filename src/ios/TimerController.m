//
//  TimerController.m
//  doclive-ui
//
//  Created by Ezequiel de Oliveira Lima on 28/11/18.
//  Copyright © 2018 Docway Aplicativo para Servicos em Saude Ltda - ME. All rights reserved.
//

#import "TimerController.h"

@implementation TimerController

@synthesize m;
@synthesize s;
@synthesize label;

- (instancetype)initWithLabel:(UILabel *)label {
    self = [super init];
    
    self.label = label;
    self.m = 0;
    self.s = 0;
    
    return self;
}

- (void) update {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        sleep(1);

        self.s++;
        
        if (self.s == 60) {
            self.s = 0;
            self.m++;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.label.text = [NSString stringWithFormat:@"%02d:%02d", self.m, self.s];
        });
        
        [self update];
    });
}

@end
