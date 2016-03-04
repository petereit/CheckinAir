//
//  FWCSubdomainViewController.m
//  CheckinAir
//
//  Created by Mark Petereit on 8/8/14.
//  Copyright (c) 2014 Family Worship Center. All rights reserved.
//

#import "FWCSubdomainViewController.h"

@interface FWCSubdomainViewController ()

@end

@implementation FWCSubdomainViewController

UIWebView *webView;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
    

}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    NSString *loginFields = [webView stringByEvaluatingJavaScriptFromString:@"(function() {return document.getElementsByClassName('login-fields').length;})();"];
    if ([loginFields isEqual: @"1"]) {
        [SVProgressHUD dismiss];
        NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
        [defaults setValue:self.subdomain.text forKey:@"SettingsSubdomain"];
        [self performSegueWithIdentifier:@"subdomainSegue" sender:self];
    } else {
        [SVProgressHUD showErrorWithStatus:@"Invalid URL!"];
        [self.subdomain isFirstResponder];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    

}

- (IBAction)subdomainChanged:(id)sender {
    UITextField *subdomain = sender;
    if (subdomain.text.length > 2) {
        self.next.enabled = true;
    } else {
        self.next.enabled = false;
    }
}

- (IBAction)nextPressed:(id)sender {
    [self.subdomain resignFirstResponder];
    
    webView = [[UIWebView alloc] init];
    webView.delegate = self;
    
    NSString *urlString = [NSString stringWithFormat:@"https://%@.breezechms.com/login", self.subdomain.text];
    NSURL *url =[NSURL URLWithString: urlString];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
    
    [SVProgressHUD showWithStatus:@"Verifying URL..." maskType:SVProgressHUDMaskTypeBlack];
    
    [webView loadRequest:request];

}
    // Called when the UIKeyboardDidShowNotification is sent.
- (void)keyboardWillShow:(NSNotification*)aNotification
    {
        NSDictionary* info = [aNotification userInfo];
        CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
        NSTimeInterval animationDuration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
        
        self.bottomConstraint.constant = kbSize.height + 20;
        
        [UIView animateWithDuration:animationDuration animations:^{
            [self.view layoutIfNeeded];
        }];
        
    }
    
    // Called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillBeHidden:(NSNotification*)aNotification
    {
        NSDictionary* info = [aNotification userInfo];
        NSTimeInterval animationDuration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
        
        self.bottomConstraint.constant = 85;
        
        [UIView animateWithDuration:animationDuration animations:^{
            [self.view layoutIfNeeded];
        }];
        
    }
    
@end
