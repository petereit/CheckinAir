//
//  FWCParentTagView.h
//  CheckinAir
//
//  Created by Mark Petereit on 2/19/16.
//  Copyright © 2016 Family Worship Center. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FWCParentTagView : UIView
@property (weak, nonatomic) IBOutlet UILabel *parent_top_1;
@property (weak, nonatomic) IBOutlet UILabel *parent_top_sub_1;
@property (weak, nonatomic) IBOutlet UILabel *parent_bottom_1;
@property (weak, nonatomic) IBOutlet UILabel *parent_bottom_sub_1;

@property (weak, nonatomic) IBOutlet UILabel *parent_top_2;
@property (weak, nonatomic) IBOutlet UILabel *parent_top_sub_2;
@property (weak, nonatomic) IBOutlet UILabel *parent_bottom_2;
@property (weak, nonatomic) IBOutlet UILabel *parent_bottom_sub_2;

@property (weak, nonatomic) IBOutlet UITextView *child_names_1;
@property (weak, nonatomic) IBOutlet UITextView *child_names_2;

@property (assign, nonatomic) NSString *code;
@property (assign, nonatomic) NSString *user_prompt;

-(void) assign_substitutions:(NSDictionary*)nametag_fields person:(NSDictionary*)person;

@end
