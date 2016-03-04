//
//  FWCLaunchImageViewController.m
//  CheckinAir
//
//  Created by Mark Petereit on 8/8/14.
//  Copyright (c) 2014 Family Worship Center. All rights reserved.
//

#import "FWCLaunchImageViewController.h"

@interface FWCLaunchImageViewController ()

@end

@implementation FWCLaunchImageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self.navigationController setNavigationBarHidden:YES];
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    double delayInSeconds = 2.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    
    //TODO: logic here that determines if they've set up the app. If it hasn't been configured yet,
    //perform the splashScreenSegue
    //otherwise perform the webViewSegue
    
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    NSString *SettingsSubdomain = [standardUserDefaults objectForKey:@"SettingsSubdomain"];

    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        if (!SettingsSubdomain) {
            [self performSegueWithIdentifier:@"splashScreenSegue" sender:self];
        } else {
            [self performSegueWithIdentifier:@"webViewSegue" sender:self];
        }
    });
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

@end
