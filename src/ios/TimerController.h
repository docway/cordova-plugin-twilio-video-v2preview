//
//  TimerController.h
//  doclive-ui
//
//  Created by Ezequiel de Oliveira Lima on 28/11/18.
//  Copyright © 2018 Docway Aplicativo para Servicos em Saude Ltda - ME. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TimerController : NSObject

@property (nonatomic) int m;
@property (nonatomic) int s;
@property (nonatomic) UILabel *label;

-(instancetype) initWithLabel:(UILabel *) label;

- (void) update;

@end
