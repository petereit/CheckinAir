//
//  FWCDonationViewController.m
//  CheckinAir
//
//  Created by Mark Petereit on 8/8/14.
//  Copyright (c) 2014 Family Worship Center. All rights reserved.
//

#import "FWCDonationViewController.h"

@interface FWCDonationViewController ()

@end

@implementation FWCDonationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)returnToDonation:(UIStoryboardSegue *)segue {
    NSLog(@"And now we are back.");
}

- (IBAction)donationButton:(id)sender {
}
@end
