//
//  FWCSubdomainViewController.h
//  CheckinAir
//
//  Created by Mark Petereit on 8/8/14.
//  Copyright (c) 2014 Family Worship Center. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SVProgressHUD.h"

@interface FWCSubdomainViewController : UIViewController <UIWebViewDelegate>
@property (strong, nonatomic) IBOutlet UITextField *subdomain;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *bottomConstraint;
@property (strong, nonatomic) IBOutlet UIButton *next;

- (IBAction)subdomainChanged:(id)sender;
- (IBAction)nextPressed:(id)sender;

@end
