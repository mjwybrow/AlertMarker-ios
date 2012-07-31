//
//  AMViewController.m
//  AlertMarker
//
//  Created by Michael Wybrow on 31/07/12.
//  Copyright (c) 2012 Monash University. All rights reserved.
//

#import "AMViewController.h"

@interface AMViewController ()

@end

@implementation AMViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
                
    // Add myLocation button to toolbar.
    UIBarButtonItem *myLocationButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"MyLocationButton.png"] style:UIBarButtonItemStylePlain target:self action:@selector(findMyLocation:)];
    [self.toolbar setItems:[NSArray arrayWithObject:myLocationButton]];
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

- (void)findMyLocation:(id)sender
{
    // Center on the user's location and start tracking.
    [self.mapView setUserTrackingMode: MKUserTrackingModeFollow animated:YES];
}


@end
