//
//  Route.h
//  SSSTest
//
//  Created by Thanh Tran on 9/22/15.
//  Copyright (c) 2015 thanhtran. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MKPointAnnotation;
@class MKPolyline;

@interface Route : NSObject{

}

@property (nonatomic, strong) MKPointAnnotation *source;
@property (nonatomic, strong) MKPointAnnotation *destination;
@property (nonatomic, strong) MKPolyline *routeOverlay;

@end
