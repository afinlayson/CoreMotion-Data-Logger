//
//  CMLViewController.m
//  CoreMotionLogger
//
//  Created by Patrick O'Keefe on 10/27/11.
//  Copyright (c) 2011 Patrick O'Keefe.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this
//  software and associated documentation files (the "Software"), to deal in the Software
//  without restriction, including without limitation the rights to use, copy, modify,
//  merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
//  permit persons to whom the Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies
//  or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
//  INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
//  PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
//  CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR
//  THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "CMLViewController.h"

@interface CMLViewController () <UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UISwitch *attitudeSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *gravitySwitch;
@property (weak, nonatomic) IBOutlet UISwitch *magneticFieldSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *rotationRateSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *userAccelerationSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *rawGyroscopeSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *rawAccelerometerSwitch;
@property (weak, nonatomic) IBOutlet UIButton *startStopButton;
@property (weak, nonatomic) IBOutlet UITextField *folderNameTextField;

@property (nonatomic) DataLogger *dataLogger;
@property (nonatomic) BOOL loggingData;
@end

@implementation CMLViewController

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    // This should never happen... unless you are storing all the data in memory (WHY?)

    // This could mean that our strings in the data logger are just getting too large
    // It's best here to stop and save what we have and throw up an alert to let the user know
    
    if (self.loggingData) {
        [self.dataLogger stopLoggingMotionDataAndSave];
        
        self.loggingData = false;
        
        // Update UI
        [self.startStopButton setTitle:@"Start" forState:UIControlStateNormal];
        self.attitudeSwitch.enabled = true;
        self.gravitySwitch.enabled = true;
        self.magneticFieldSwitch.enabled = true;
        self.rotationRateSwitch.enabled = true;
        self.userAccelerationSwitch.enabled = true;
        self.rawGyroscopeSwitch.enabled = false;
        self.rawAccelerometerSwitch.enabled = false;
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Need Moar Memory!"
                                                            message:@"The device is running out of memory. Logging has been stopped and the files have been saved. Feel free to start again!"
                                                           delegate:nil
                                                  cancelButtonTitle:@"Darn"
                                                  otherButtonTitles:nil];
        [alertView show];
    }

}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.dataLogger = [[DataLogger alloc] init];
    self.loggingData = NO;
    
    // Inform the data logger about the default values of the switches
    [self.dataLogger setLogAttitudeData:self.attitudeSwitch.on];
    [self.dataLogger setLogGravityData:self.gravitySwitch.on];
    [self.dataLogger setLogMagneticFieldData:self.magneticFieldSwitch.on];
    [self.dataLogger setLogRotationRateData:self.rotationRateSwitch.on];
    [self.dataLogger setLogUserAccelerationData:self.userAccelerationSwitch.on];
    [self.dataLogger setLogRawGyroscopeData:self.rawGyroscopeSwitch.on];
    [self.dataLogger setLogRawAccelerometerData:self.rawAccelerometerSwitch.on];
    
    self.startStopButton.layer.cornerRadius = 10;
    self.startStopButton.layer.borderColor = [UIColor blueColor].CGColor;
    self.startStopButton.layer.borderWidth = 0.5;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

#pragma mark - UI Event Handlers

- (IBAction)startStopButtonPressed:(id)sender
{
    
    if (self.loggingData) {
        
        [self.dataLogger stopLoggingMotionDataAndSave];
        
        self.loggingData = false;
        
        // Update UI
        [self.startStopButton setTitle:@"Start" forState:UIControlStateNormal];
        self.attitudeSwitch.enabled = true;
        self.gravitySwitch.enabled = true;
        self.magneticFieldSwitch.enabled = true;
        self.rotationRateSwitch.enabled = true;
        self.userAccelerationSwitch.enabled = true;
        self.rawGyroscopeSwitch.enabled = false;
        self.rawAccelerometerSwitch.enabled = false;
        
    } else {
        
        self.dataLogger.name = self.folderNameTextField.text;
        [self.dataLogger startLoggingMotionData];
        
        self.loggingData = true;

        // Update UI
        [self.startStopButton setTitle:@"Stop and Save" forState:UIControlStateNormal];
        self.attitudeSwitch.enabled = false;
        self.gravitySwitch.enabled = false;
        self.magneticFieldSwitch.enabled = false;
        self.rotationRateSwitch.enabled = false;
        self.userAccelerationSwitch.enabled = false;
        self.rawGyroscopeSwitch.enabled = false;
        self.rawAccelerometerSwitch.enabled = false;

    }    
    
}

- (IBAction)switchToggled:(UISwitch*)sender
{
    
    if (sender == self.attitudeSwitch) {
        [self.dataLogger setLogAttitudeData:sender.on];
    } else if (sender == self.gravitySwitch) {
        [self.dataLogger setLogGravityData:sender.on];
    } else if (sender == self.magneticFieldSwitch) {
        [self.dataLogger setLogMagneticFieldData:sender.on];
    } else if (sender == self.rotationRateSwitch) {
        [self.dataLogger setLogRotationRateData:sender.on];
    } else if (sender == self.userAccelerationSwitch) {
        [self.dataLogger setLogUserAccelerationData:sender.on];
    } else if (sender == self.rawGyroscopeSwitch) {
        [self.dataLogger setLogRawGyroscopeData:sender.on];
    } else if (sender == self.rawAccelerometerSwitch) {
        [self.dataLogger setLogRawAccelerometerData:sender.on];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return NO;
}

@end
