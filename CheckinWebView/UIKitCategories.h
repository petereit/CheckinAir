//
//  UIKitCategories.h
//  CheckinAir
//
//  Created by Mark Petereit on 2/25/17.
//  Copyright © 2017 Family Worship Center. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UIView (FindUIViewController)
- (UIViewController *) firstAvailableUIViewController;
- (id) traverseResponderChainForUIViewController;
@end
