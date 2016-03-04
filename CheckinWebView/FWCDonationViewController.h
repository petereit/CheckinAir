//
//  FWCDonationViewController.h
//  CheckinAir
//
//  Created by Mark Petereit on 8/8/14.
//  Copyright (c) 2014 Family Worship Center. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FWCDonationViewController : UIViewController

@property (strong, nonatomic) IBOutlet UIButton *smallButton;
@property (strong, nonatomic) IBOutlet UIButton *mediumButton;
@property (strong, nonatomic) IBOutlet UIButton *largeButton;
@property (strong, nonatomic) IBOutlet UIButton *megaButton;
@property (strong, nonatomic) IBOutlet UIButton *remindMeButton;

- (IBAction)returnToDonation:(UIStoryboardSegue *)segue;
- (IBAction)donationButton:(id)sender;

@end
