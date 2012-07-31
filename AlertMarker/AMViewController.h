//
//  AMViewController.h
//  AlertMarker
//
//  Created by Michael Wybrow on 31/07/12.
//  Copyright (c) 2012 Monash University. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MKMapView.h>

@interface AMViewController : UIViewController <MKMapViewDelegate>

@property (strong, nonatomic) IBOutlet MKMapView *mapView;
@property (strong, nonatomic) IBOutlet UIToolbar *toolbar;


@end
