//
//  AMViewController.m
//  AlertMarker
//
//  Created by Michael Wybrow on 31/07/12.
//  Copyright (c) 2012 Monash University. All rights reserved.
//

#import <MapKit/MKUserLocation.h>
#import <MapKit/MKPinAnnotationView.h>
#import <MapKit/MKAnnotation.h>
#import <sqlite3.h>
#import "AMViewController.h"

@interface AMViewController ()
{
    CLGeocoder *geocoder;
    BOOL geocoderIsBusy;
    sqlite3 *locationDatabase;
}

@end

@implementation AMViewController


#pragma mark -
#pragma mark UIViewController lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
                
    // Add myLocation button to toolbar.
    UIBarButtonItem *myLocationButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"MyLocationButton.png"] style:UIBarButtonItemStylePlain target:self action:@selector(findMyLocation:)];
    [self.toolbar setItems:[NSArray arrayWithObject:myLocationButton]];

    // Geocoder is used for looking up addresses.
    geocoder = [[CLGeocoder alloc] init];
    
    // Set the delegate so we can respond to user location changes (and lookup addresses)
    self.mapView.delegate = self;

    // Recognise a long press of 1 second.
    UILongPressGestureRecognizer *lpgr = [[UILongPressGestureRecognizer alloc] 
                                          initWithTarget:self action:@selector(addLocationPin:)];
    lpgr.minimumPressDuration = 1.0;
    lpgr.cancelsTouchesInView = NO;
    [self.mapView addGestureRecognizer:lpgr];

    // Try to open database.  sqlite3_open will create DB if it doesn't exist.
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL dbExists = [fileManager fileExistsAtPath:self.databasePath];
    if (sqlite3_open([self.databasePath UTF8String], &locationDatabase) != SQLITE_OK)
    {
        locationDatabase = nil;
        NSLog(@"Database failed to load");
    }

    if (dbExists == NO)
    {
        // Create the locations table.
        NSString *sql = @"CREATE TABLE locations (latitude REAL, logitude REAL, address TEXT);";
        sqlite3_exec(locationDatabase, [sql UTF8String], NULL, NULL, NULL);
    }
    else
    {
        [self loadState];
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.

    if (locationDatabase)
    {
        sqlite3_close(locationDatabase);
        locationDatabase = nil;
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

#pragma mark -
#pragma mark Location helper code

- (void)findMyLocation:(id)sender
{
    // Center on the user's location and start tracking.
    [self.mapView setUserTrackingMode: MKUserTrackingModeFollow animated:YES];
}

- (NSString *)addressStringFromPlacemarks:(NSArray *)placemarks
{
    // Build an address string from the first placemark returned by the reverse geocoder.
    if(placemarks && placemarks.count > 0)
    {
        CLPlacemark *topResult = [placemarks objectAtIndex:0];
        return [NSString stringWithFormat:@"%@ %@, %@ %@", ([topResult subThoroughfare] ? [topResult subThoroughfare] : @""), [topResult thoroughfare], [topResult locality], [topResult administrativeArea]];
    }
    return nil;
}

- (void)addLocationPin:(UIGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer.state != UIGestureRecognizerStateBegan) {
        return;
    }

    // Find the touch location on the map.
    CGPoint touchPoint = [gestureRecognizer locationInView:self.mapView];
    CLLocationCoordinate2D touchMapCoordinate = [self.mapView convertPoint:touchPoint toCoordinateFromView:self.mapView];
    
    // Create an annotation for the location
    MKPointAnnotation *annotion = [[MKPointAnnotation alloc] init];
    annotion.coordinate = touchMapCoordinate;
    annotion.title = @"Pin";
    [self.mapView addAnnotation:annotion];
    
    NSLog(@"Long press as latitude: %f, longitude: %f", touchMapCoordinate.latitude, touchMapCoordinate.longitude);

    // Asyncronously find the address for the location.
    CLLocation *location = [[CLLocation alloc] initWithLatitude:touchMapCoordinate.latitude longitude:touchMapCoordinate.longitude];
    [geocoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error) {
        NSLog(@"handleLongPress: reverseGeocodeLocation: Completion Handler called!");
        
        annotion.title = [self addressStringFromPlacemarks:placemarks];
    }];
}


#pragma mark -
#pragma mark MKMapView delegate

- (void)mapView:(MKMapView *)thisMapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    // The user's location updated.
    
    // Request asyncronous reverse geocoding of the location, if there isn't a request in progress.
    if (geocoderIsBusy == NO)
    {
        // We're working on a request.
        geocoderIsBusy = YES;

        [geocoder reverseGeocodeLocation:userLocation.location completionHandler:^(NSArray *placemarks, NSError *error) {
            NSLog(@"didUpdateUserLocation: reverseGeocodeLocation: Completion Handler called!");
            
            thisMapView.userLocation.title = [self addressStringFromPlacemarks:placemarks];
            
            // Finished.
            geocoderIsBusy = NO;
        }];
    }
}

- (MKAnnotationView *)mapView:(MKMapView *)thisMapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    // Create the Pin Annotation View ourselves, so we can add a delete button to it.
    if ([annotation isKindOfClass:[MKUserLocation class]])
    {
        // userLocation is a special Pin Annotation View.  Don't replace this.
        return nil;
    }

    //These pin views are added to a resuse queue when they are deleted, so we try taking one from the reuse queue...
    MKPinAnnotationView *pinView = (MKPinAnnotationView *)[thisMapView dequeueReusableAnnotationViewWithIdentifier:@"pinView"];
    if (!pinView)
    {
        // Otherwise we create and initialise a new one.
        pinView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"pinView"];
        pinView.pinColor = MKPinAnnotationColorRed;
        pinView.animatesDrop = YES;
        pinView.canShowCallout = YES;

        // Add the delete button to the annotation callout
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *img = [UIImage imageNamed:@"DeleteButton.png"];
        button.frame = CGRectMake(0, 0, img.size.width, img.size.height);
        [button setImage:img forState:UIControlStateNormal];
        button.contentMode = UIViewContentModeScaleToFill;
        pinView.rightCalloutAccessoryView = button;
    }
    else
    {
        pinView.annotation = annotation;
    }
    
    return pinView;
}

- (void)mapView:(MKMapView *)thisMapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
    // This is called when the user taps the accessory view in a pin annotation view, that is our delete button.
    [thisMapView removeAnnotation:view.annotation];
}

#pragma mark -
#pragma mark Persistent storage

- (NSString *)databasePath
{
    NSString *databaseName = @"locations.db";
    
    // Get the path to the documents directory and append the databaseName
    NSArray *documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDir = [documentPaths objectAtIndex:0];
    return [documentsDir stringByAppendingPathComponent:databaseName];
}

- (void)saveState
{
    if (locationDatabase)
    {
        // CLear the table.
        NSString *sql = @"DELETE FROM locations;";
        sqlite3_exec(locationDatabase, [sql UTF8String], NULL, NULL, NULL);
        
        // Save user-created pin locations.
        for (MKShape *annotation in self.mapView.annotations)
        {
            // Don't store the userLocation annotation.
            if ([annotation isEqual:self.mapView.userLocation] == NO)
            {
                // Create the locations table.
                sql = [NSString stringWithFormat:@"INSERT INTO locations(latitude, logitude, address) VALUES(%f, %f, '%@');", annotation.coordinate.latitude, annotation.coordinate.longitude, annotation.title];
                sqlite3_exec(locationDatabase, [sql UTF8String], NULL, NULL, NULL);
            }
        }
    }
}

- (void)loadState
{
    // Load saved locations.
    sqlite3_stmt *compiledStatement = nil;        
    NSString *sql = @"SELECT latitude, logitude, address FROM locations";
    if (sqlite3_prepare_v2(locationDatabase, [sql UTF8String], -1, &compiledStatement, NULL) == SQLITE_OK)
    {
        while (sqlite3_step(compiledStatement) == SQLITE_ROW) 
        {
            CLLocationDegrees latitude = (CLLocationDegrees) sqlite3_column_double(compiledStatement, 0);
            CLLocationDegrees longitude = (CLLocationDegrees) sqlite3_column_double(compiledStatement, 1);
            NSString *address = [NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledStatement, 2)];
            
            CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(latitude, longitude);
            
            // Create an annotation for the location
            MKPointAnnotation *annotion = [[MKPointAnnotation alloc] init];
            annotion.coordinate = coordinate;
            annotion.title = address;
            [self.mapView addAnnotation:annotion];
        }
    }
    sqlite3_finalize(compiledStatement);
}


@end
