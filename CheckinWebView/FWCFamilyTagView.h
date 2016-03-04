//
//  FWCFamilyTagView.h
//  CheckinAir
//
//  Created by Mark Petereit on 2/19/16.
//  Copyright © 2016 Family Worship Center. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FWCFamilyTagView : UIView
@property (weak, nonatomic) IBOutlet UILabel *family_top_1;
@property (weak, nonatomic) IBOutlet UILabel *family_sub_top_1;
@property (weak, nonatomic) IBOutlet UITextView *family_names_1;
@property (weak, nonatomic) IBOutlet UILabel *family_bottom_1;

@property (weak, nonatomic) IBOutlet UILabel *family_top_2;
@property (weak, nonatomic) IBOutlet UILabel *family_sub_top_2;
@property (weak, nonatomic) IBOutlet UITextView *family_names_2;
@property (weak, nonatomic) IBOutlet UILabel *family_bottom_2;

@property (assign, nonatomic) NSString *code;
@property (assign, nonatomic) NSString *user_prompt;

-(void) assign_substitutions:(NSDictionary*)nametag_fields person:(NSDictionary*)person;

@end
