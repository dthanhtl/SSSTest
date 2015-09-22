//
//  AutoCompleteTableView.h
//  SSSTest
//
//  Created by Thanh Tran on 9/22/15.
//  Copyright (c) 2015 thanhtran. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AutoCompleteTableView : UITableView <UITableViewDelegate, UITableViewDataSource>{
}

@property (nonatomic, strong) NSArray *dataArray;

@end
