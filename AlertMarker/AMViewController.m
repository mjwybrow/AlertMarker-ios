//
//  AMViewController.m
//  AlertMarker
//
//  Created by Michael Wybrow on 31/07/12.
//  Copyright (c) 2012 Monash University. All rights reserved.
//

#import <MapKit/MKUserLocation.h>
#import "AMViewController.h"

@interface AMViewController ()
{
    CLGeocoder *geocoder;
    BOOL geocoderIsBusy;
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

}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
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

@end
