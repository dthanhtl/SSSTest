//
//  ViewController.h
//  SSSTest
//
//  Created by Thanh Tran on 9/22/15.
//  Copyright (c) 2015 thanhtran. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@interface ViewController : UIViewController<MKMapViewDelegate, CLLocationManagerDelegate, UISearchBarDelegate>{

}

@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *indicator;



@end

