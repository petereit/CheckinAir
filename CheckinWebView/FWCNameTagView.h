//
//  FWCNameTagView.h
//  CheckinAir
//
//  Created by Mark Petereit on 2/19/16.
//  Copyright © 2016 Family Worship Center. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FWCFamilyTagView.h"

@interface FWCNameTagView : UIView <NSURLConnectionDelegate, NSURLSessionDelegate>

@property (weak, nonatomic) IBOutlet UILabel *child_top_left;
@property (weak, nonatomic) IBOutlet UILabel *child_top_right;
@property (weak, nonatomic) IBOutlet UIImageView *child_image;
@property (weak, nonatomic) IBOutlet UILabel *child_name;
@property (weak, nonatomic) IBOutlet UILabel *child_sub_name;
@property (weak, nonatomic) IBOutlet UILabel *child_bottom_left;
@property (weak, nonatomic) IBOutlet UILabel *child_bottom_right;
@property (weak, nonatomic) IBOutlet UIStackView *imageStackView;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *imageWidth;
@property (strong, nonatomic) IBOutletCollection(UILabel) NSArray *labelCollection;

@property (assign, nonatomic) NSString *code;
@property (assign, nonatomic) NSString *user_prompt;
@property (assign, nonatomic) NSDictionary *nametag_fields;
@property (assign, nonatomic) NSString *person_id;
@property (assign, nonatomic) NSString *instance_id;
@property (assign, nonatomic) NSString *people_ids_json;
@property (assign, nonatomic) NSDictionary *person;
@property (assign, nonatomic) NSString *logoText;

@property (assign, nonatomic) FWCFamilyTagView *parentTag;

-(void) create_tag:(NSDictionary *)nametag_fields person_id:(NSString *)person_id;

@end
