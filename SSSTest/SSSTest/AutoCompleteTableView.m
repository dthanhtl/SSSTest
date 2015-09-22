//
//  AutoCompleteTableView.m
//  SSSTest
//
//  Created by Thanh Tran on 9/22/15.
//  Copyright (c) 2015 thanhtran. All rights reserved.
//

#import "AutoCompleteTableView.h"
#import <MapKit/MapKit.h>

@implementation AutoCompleteTableView{
    CGFloat originalHeight;
    CGFloat currentHeight;

}

- (id)initWithFrame:(CGRect)frame style:(UITableViewStyle)style {
    self = [super initWithFrame:frame style:style];
    if (self) {
        self.delegate = self;
        self.dataSource = self;
        
        [self registerClass:[UITableViewCell class] forCellReuseIdentifier:@"autocompleteCell"];
        self.scrollEnabled = YES;
        originalHeight = frame.size.height;
    }
    
    return self;
}

- (void)setDataArray:(NSArray *)dataArray {
    _dataArray = nil;
    _dataArray = dataArray;
    [self reloadData];
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"autocompleteCell" forIndexPath:indexPath];
    MKMapItem *mapItem = _dataArray[indexPath.row];
    
    if (mapItem.placemark.title.length > 0)
        cell.textLabel.text = mapItem.placemark.title;
    else
        cell.textLabel.text = mapItem.placemark.description;
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 40;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"NotificationAutoCompleteRowSelected"
                                                        object:nil
                                                      userInfo:@{@"NotificationAutoCompleteRowSelected":self.dataArray[indexPath.row]}];
}

@end
