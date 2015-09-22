//
//  ViewController.m
//  SSSTest
//
//  Created by Thanh Tran on 9/22/15.
//  Copyright (c) 2015 thanhtran. All rights reserved.
//

#import "ViewController.h"
#import "AutoCompleteTableView.h"
#import "Route.h"


@interface ViewController ()

@property (strong, nonatomic) CLLocationManager *locationManager;

@property (strong, nonatomic) AutoCompleteTableView *autoCompleteTableView;

@property (strong, nonatomic) UILongPressGestureRecognizer *longPress;

@property (strong, nonatomic) MKPointAnnotation *centerAnno;
@property (strong, nonatomic) NSString *lastSearch;
@property (strong, nonatomic) Route *route;
@property (nonatomic) CGFloat tableHeight;

@end

@implementation ViewController


#pragma mark -- life circle



- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    
    
//    }
    
    self.locationManager = [[CLLocationManager alloc] init];
    
    if(IS_OS_8_OR_LATER) {
        // Use one or the other, not both. Depending on what you put in info.plist
        [self.locationManager requestWhenInUseAuthorization];
        self.locationManager.delegate = self;
//        [self.locationManager requestAlwaysAuthorization];
    }
    
    [self.locationManager startUpdatingLocation];
    
    
    [self.mapView setShowsUserLocation:YES];
//    [self.mapView setMapType:MKMapTypeStandard];
//    [self.mapView setZoomEnabled:YES];
//    [self.mapView setScrollEnabled:YES];
    
    
    self.centerAnno = [[MKPointAnnotation alloc] init];
    self.centerAnno.coordinate = self.mapView.centerCoordinate;
    self.centerAnno.title = @"Current Location";
    [self.mapView addAnnotation:self.centerAnno];
    [self.mapView selectAnnotation:self.centerAnno animated:NO];
    
    [self.autoCompleteTableView setDataArray:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didSelectAutoCompleteRow:) name:@"NotificationAutoCompleteRowSelected" object:nil];
    
    //long press to set a new location --> get direction
    self.longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressTapped:)];
    [self.view addGestureRecognizer:self.longPress];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -- gesture

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    
    CGPoint touchPoint = [touch locationInView:self.view];
    
    if (!CGRectContainsPoint(self.autoCompleteTableView.frame, touchPoint)) {
        self.autoCompleteTableView.hidden = YES;
        [self.searchBar resignFirstResponder];
    }
}

- (void)longPressTapped:(UILongPressGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        CGPoint point = [recognizer locationInView:self.view];
        
        CLLocationCoordinate2D locCoord2d = [self.mapView convertPoint:point toCoordinateFromView:self.mapView];
        CLLocation *location = [[CLLocation alloc] initWithLatitude:locCoord2d.latitude longitude:locCoord2d.longitude];
        
        CLGeocoder *geoCoder = [[CLGeocoder alloc] init];
        [geoCoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error) {
            if (placemarks.count > 0) {
                MKPlacemark *placemark = [[MKPlacemark alloc] initWithPlacemark:[placemarks firstObject]];
                MKMapItem *mapItem = [[MKMapItem alloc] initWithPlacemark:placemark];
                [self.indicator startAnimating];
                [self calculateRouteToMapItem:mapItem];
            }
        }];
    }
}

#pragma mark - MapViewDelegate

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation {
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(userLocation.coordinate, 1000, 1000);
    [self.mapView setRegion:[self.mapView regionThatFits:region] animated:YES];
    
    [self.mapView setUserTrackingMode:MKUserTrackingModeNone];
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
    CLLocationCoordinate2D newCoord2D = [self.mapView centerCoordinate];
    
    self.centerAnno.coordinate = newCoord2D;
    
    CLLocation *location = [[CLLocation alloc] initWithLatitude:newCoord2D.latitude longitude:newCoord2D.longitude];
    
    //Get address from location (latitude, longtitude)
    CLGeocoder *geoCoder = [[CLGeocoder alloc] init];
    [geoCoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error) {
        if (placemarks.count > 0) {
            CLPlacemark *placemark = placemarks[0];
            
            self.centerAnno.title = placemark.addressDictionary[@"Name"];
            [self.mapView selectAnnotation:self.centerAnno animated:NO];
        }
    }];
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay
{
    MKPolylineRenderer *renderer = [[MKPolylineRenderer alloc] initWithPolyline:overlay];
    renderer.strokeColor = [UIColor redColor];
    renderer.lineWidth = 4.0;
    return  renderer;
}

- (void)calculateRouteToMapItem:(MKMapItem *)mapItem {
    MKPointAnnotation *sourceAnnotaion = [MKPointAnnotation new];
    sourceAnnotaion.coordinate = self.mapView.userLocation.coordinate;
    sourceAnnotaion.title = @"Your location";
    
    MKPointAnnotation *destinationAnnotation = [MKPointAnnotation new];
    destinationAnnotation.coordinate = mapItem.placemark.coordinate;
    destinationAnnotation.title = mapItem.placemark.title;
    
    MKMapItem *sourceMapItem = [MKMapItem mapItemForCurrentLocation];
    MKMapItem *destinationMapItem = mapItem;
    
    [self obtainDirectionsFrom:sourceMapItem to:destinationMapItem completion:^(MKRoute *route, NSError *error) {
        if (route) {
            Route *newRoute = [Route new];
            newRoute.source = sourceAnnotaion;
            newRoute.destination = destinationAnnotation;
            newRoute.routeOverlay = route.polyline;
            
            [self setupWithNewRoute:newRoute];
        } else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"...."
                                                            message:@"Direction not found"
                                                           delegate:nil
                                                  cancelButtonTitle:nil
                                                  otherButtonTitles:@"OK", nil];
            [alert show];
        }
        
        [self.indicator stopAnimating];
    }];
}

- (void)obtainDirectionsFrom:(MKMapItem*)from to:(MKMapItem*)to completion:(void(^)(MKRoute *route, NSError *error))completion {
    MKDirectionsRequest *request = [[MKDirectionsRequest alloc] init];
    
    request.source = from;
    request.destination = to;
    
    request.transportType = MKDirectionsTransportTypeAutomobile;
    
    MKDirections *directions = [[MKDirections alloc] initWithRequest:request];
    [directions calculateDirectionsWithCompletionHandler:^(MKDirectionsResponse *response, NSError *error) {
        MKRoute *route = nil;
        
        if (response.routes.count > 0) {
            route = [response.routes firstObject];
        } else if (!error) {
            
        }
        
        if (completion) {
            completion(route, error);
        }
    }];
}

- (void)setupWithNewRoute:(Route*)route {
    if (self.route) {
        [self.mapView removeAnnotations:@[self.route.source, self.route.destination]];
        [self.mapView removeOverlays:@[_route.routeOverlay]];
        self.route = nil;
    }
    
    self.route = route;
    
    [self.mapView addAnnotations:@[route.source, route.destination]];
    [self.mapView addOverlay:route.routeOverlay level:MKOverlayLevelAboveRoads];
}

#pragma mark - searchBar Delegate

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    self.searchBar.showsCancelButton = YES;
    
    self.autoCompleteTableView.hidden = NO;
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    self.searchBar.showsCancelButton = NO;
    self.autoCompleteTableView.hidden = YES;
    [self.searchBar resignFirstResponder];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    self.searchBar.showsCancelButton = NO;
    self.autoCompleteTableView.hidden = YES;
    [self.searchBar resignFirstResponder];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    self.searchBar.showsCancelButton = NO;
    [self.searchBar resignFirstResponder];
    self.searchBar.text = self.lastSearch;
    
    [self getAutoCompleteDataWithLocationName:self.lastSearch];
    
    self.autoCompleteTableView.hidden = NO;
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(getAutoCompleteDataWithLocationName:) object:self.lastSearch];
    
    self.lastSearch = searchText;
    
    [self performSelector:@selector(getAutoCompleteDataWithLocationName:) withObject:searchText afterDelay:0.3];
}

#pragma mark - Autocomplete TableView Support
-(AutoCompleteTableView *)autoCompleteTableView {
    if (!_autoCompleteTableView) {
        CGFloat height = CGRectGetMaxY(self.view.frame) - CGRectGetMaxY(self.searchBar.frame);
        self.tableHeight = height/2;
        
        self.autoCompleteTableView = [[AutoCompleteTableView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.searchBar.frame), self.view.bounds.size.width, 0) style:UITableViewStylePlain];
        
        [self.view addSubview:self.autoCompleteTableView];
        [self.view sendSubviewToBack:self.mapView];
        
        [self.autoCompleteTableView setHidden:YES];
    }
    return _autoCompleteTableView;
}


- (void)didSelectAutoCompleteRow:(NSNotification *)notification {
    if ([notification.name isEqualToString:@"NotificationAutoCompleteRowSelected"]) {
        [self.searchBar resignFirstResponder];
        MKMapItem *mapItem = notification.userInfo[@"NotificationAutoCompleteRowSelected"];
        
        [self.autoCompleteTableView setHidden:YES];
        
        //Setup route to the choosen location
        [self.indicator startAnimating];
        [self calculateRouteToMapItem:mapItem];
    }
}

- (void)getAutoCompleteDataWithLocationName:(NSString *)searchString {
    if (searchString.length == 0)
        return;
    
    [self.indicator startAnimating];
    
    MKLocalSearchRequest *searchRequest = [[MKLocalSearchRequest alloc] init];
    searchRequest.naturalLanguageQuery = searchString;
    
    MKLocalSearch *search = [[MKLocalSearch alloc] initWithRequest:searchRequest];
    [search startWithCompletionHandler:^(MKLocalSearchResponse *response, NSError *error) {
        if (response.mapItems.count > 0) {
            [self resizeAutoCompleteTableViewToFitNumberOfItems:response.mapItems.count];
            [self.autoCompleteTableView setDataArray:response.mapItems];
        }
        
        [self.indicator stopAnimating];
    }];
}

- (void)resizeAutoCompleteTableViewToFitNumberOfItems:(NSInteger)numOfRow {
    CGFloat estimateHeight = numOfRow * 40;
    CGFloat newHeigh = estimateHeight > self.tableHeight ? self.tableHeight : estimateHeight;
    
    self.autoCompleteTableView.frame = CGRectMake(self.autoCompleteTableView.frame.origin.x,
                                                  self.autoCompleteTableView.frame.origin.y,
                                                  self.autoCompleteTableView.frame.size.width,
                                                  newHeigh);
}





@end
