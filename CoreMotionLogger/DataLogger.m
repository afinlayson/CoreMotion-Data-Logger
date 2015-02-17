//
//  DataLogger.m
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

#import "DataLogger.h"

static NSString * const kAttitudeFileName = @"Attitude.txt"; // Is this Altitude?
static NSString * const kGravityFileName = @"Gravity.txt";
static NSString * const kMagneticFileName = @"Magnetic.txt";
static NSString * const kRotationFileName = @"Rotation.txt";
static NSString * const kUserAccelerationFileName = @"UserAcceleration.txt";
static NSString * const kRawGyroscopeFileName = @"RawGyroscope.txt";
static NSString * const kRawAccelerationFileName = @"RawAcceleration.txt";

@interface DataLogger ()
@property (nonatomic) CMMotionManager *motionManager;
@property (nonatomic) NSOperationQueue *deviceMotionQueue;
@property (nonatomic) NSOperationQueue *accelQueue;
@property (nonatomic) NSOperationQueue *gyroQueue;

@property (nonatomic) BOOL logAttitudeData;
@property (nonatomic) BOOL logGravityData;
@property (nonatomic) BOOL logMagneticFieldData;
@property (nonatomic) BOOL logRotationRateData;
@property (nonatomic) BOOL logUserAccelerationData;
@property (nonatomic) BOOL logRawGyroscopeData;
@property (nonatomic) BOOL logRawAccelerometerData;

@property (nonatomic) NSString *folderPath;

@property (nonatomic) NSFileHandle *handleAttitudeData;
@property (nonatomic) NSFileHandle *handleGravityData;
@property (nonatomic) NSFileHandle *handleMagneticFieldData;
@property (nonatomic) NSFileHandle *handleRotationRateData;
@property (nonatomic) NSFileHandle *handleUserAccelerationData;
@property (nonatomic) NSFileHandle *handleRawGyroscopeData;
@property (nonatomic) NSFileHandle *handleRawAccelerometerData;
@end

@implementation DataLogger

- (instancetype)init
{
    self = [super init];
    if (self) {

        self.motionManager = [[CMMotionManager alloc] init];
        self.motionManager.deviceMotionUpdateInterval = 0.01; //100 Hz
        self.motionManager.accelerometerUpdateInterval = 0.01;
        self.motionManager.gyroUpdateInterval = 0.01;

        // Limiting the concurrent ops to 1 is a cheap way to avoid two handlers editing the same
        // string at the same time.
        
        self.deviceMotionQueue = [[NSOperationQueue alloc] init];
        [self.deviceMotionQueue setMaxConcurrentOperationCount:1];

        self.accelQueue = [[NSOperationQueue alloc] init];
        [self.accelQueue setMaxConcurrentOperationCount:1];

        self.gyroQueue = [[NSOperationQueue alloc] init];
        [self.gyroQueue setMaxConcurrentOperationCount:1];

        self.logAttitudeData = false;
        self.logGravityData = false;
        self.logMagneticFieldData = false;
        self.logRotationRateData = false;
        self.logUserAccelerationData = false;
        self.logRawGyroscopeData = false;
        self.logRawAccelerometerData = false;
    }

    return self;
}

+ (NSString *) applicationDocumentsDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return basePath;
}


- (void) startLoggingMotionData
{

    NSLog(@"Starting to log motion data.");
    
    if (!self.folderPath) {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setTimeStyle:NSDateFormatterLongStyle];
        [dateFormatter setDateStyle:NSDateFormatterShortStyle];
        
        // Some filesystems hate colons
        NSString *dateString = [[dateFormatter stringFromDate:[NSDate date]] stringByReplacingOccurrencesOfString:@":" withString:@"self."];
        // I hate spaces
        dateString = [dateString stringByReplacingOccurrencesOfString:@" " withString:@"self."];
        // Nobody can stand forward slashes
        dateString = [dateString stringByReplacingOccurrencesOfString:@"/" withString:@"self."];
        
        self.folderPath = [[DataLogger applicationDocumentsDirectory] stringByAppendingPathComponent:dateString];
    }

    CMDeviceMotionHandler motionHandler = ^(CMDeviceMotion *motion, NSError *error) {
        [self processMotion:motion withError:error];
    };

    CMGyroHandler gyroHandler = ^(CMGyroData *gyroData, NSError *error) {
        [self processGyro:gyroData withError:error];
    };

    CMAccelerometerHandler accelHandler = ^(CMAccelerometerData *accelerometerData, NSError *error) {
        [self processAccel:accelerometerData withError:error];
    };


    if (self.logAttitudeData || self.logGravityData || self.logMagneticFieldData || self.logRotationRateData || self.logUserAccelerationData ) {
        [self.motionManager startDeviceMotionUpdatesToQueue:self.deviceMotionQueue withHandler:motionHandler];
    }

    if (self.logRawGyroscopeData) {
        [self.motionManager startGyroUpdatesToQueue:self.gyroQueue withHandler:gyroHandler];
    }

    if (self.logRawAccelerometerData) {
        [self.motionManager startAccelerometerUpdatesToQueue:self.accelQueue withHandler:accelHandler];
    }
    
    [self openFileHandles];
}

- (void)openFileHandles
{
    BOOL shouldAppendFile = self.shouldAppendFile;
    NSFileHandle *(^createFileHandler)(NSString *fileName) = ^NSFileHandle *(NSString *fileName){
        if ([[NSFileManager defaultManager] fileExistsAtPath:fileName]) {
            NSError *error;
            if (!shouldAppendFile) {
                [[NSFileManager defaultManager] removeItemAtPath:fileName error:&error];
                if (error) {
                    NSLog(@"Error found removing file %@: %@", fileName, error);
                }
            }
        } else {
            [[NSFileManager defaultManager] createFileAtPath:fileName contents:[NSData data] attributes:nil];
        }
        return [NSFileHandle fileHandleForWritingAtPath:fileName];
    };
    
    BOOL isfolder = NO;
    NSError *error;
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.folderPath isDirectory:&isfolder]) {
        if (!isfolder) {
            [[NSFileManager defaultManager] removeItemAtPath:self.folderPath error:&error];
            if (error) {
                NSLog(@"There was an error trying to remove this file: %@" ,self.folderPath);
                NSLog(@"%@",error);
            }
        }
    } else {
        [[NSFileManager defaultManager] createDirectoryAtPath:self.folderPath withIntermediateDirectories:NO attributes:nil error:&error];
        if (error) {
            NSLog(@"There was an error trying to create this folder: %@" ,self.folderPath);
            NSLog(@"%@",error);
        }
    }
    
    if (self.logAttitudeData) {
        self.handleAttitudeData = createFileHandler([self.folderPath stringByAppendingPathComponent:kAttitudeFileName]);
    }
    if (self.logGravityData) {
        
        self.handleGravityData = createFileHandler([self.folderPath stringByAppendingPathComponent:kGravityFileName]);
    }
    if (self.logMagneticFieldData) {
        self.handleMagneticFieldData = createFileHandler([self.folderPath stringByAppendingPathComponent:kMagneticFileName]);
    }
    if (self.logRawAccelerometerData) {
        self.handleRawAccelerometerData = createFileHandler([self.folderPath stringByAppendingPathComponent:kRawAccelerationFileName]);
    }
    if (self.logRawGyroscopeData) {
        self.handleRawGyroscopeData = createFileHandler([self.folderPath stringByAppendingPathComponent:kRawGyroscopeFileName]);
    }
    if (self.logRotationRateData) {
        self.handleRotationRateData = createFileHandler([self.folderPath stringByAppendingPathComponent:kUserAccelerationFileName]);
    }
    if (self.logRotationRateData) {
        self.handleUserAccelerationData = createFileHandler([self.folderPath stringByAppendingPathComponent:kUserAccelerationFileName]);
    }
}

- (void)finishWriting
{
    [self.handleAttitudeData closeFile];
    [self.handleGravityData closeFile];
    [self.handleMagneticFieldData closeFile];
    [self.handleRawAccelerometerData closeFile];
    [self.handleRawGyroscopeData closeFile];
    [self.handleRotationRateData closeFile];
    [self.handleUserAccelerationData closeFile];
}

- (void)stopLoggingMotionDataAndSave {

    NSLog(@"Stopping data logging.");

    [self.motionManager stopDeviceMotionUpdates];
    [self.deviceMotionQueue waitUntilAllOperationsAreFinished];

    [self.motionManager stopAccelerometerUpdates];
    [self.accelQueue waitUntilAllOperationsAreFinished];

    [self.motionManager stopGyroUpdates];
    [self.gyroQueue waitUntilAllOperationsAreFinished];

    // Save all of the data!
    [self finishWriting];
}

- (void)processAccel:(CMAccelerometerData*)accelData withError:(NSError*)error {

    if (self.logRawAccelerometerData) {
        NSString *rawAccelerometerString = [NSString stringWithFormat:@"%f,%f,%f,%f\n", accelData.timestamp,
                                                           accelData.acceleration.x,
                                                           accelData.acceleration.y,
                                                           accelData.acceleration.z,
                                                           nil];
        
        [self.handleRawAccelerometerData writeData:[rawAccelerometerString dataUsingEncoding:NSUTF8StringEncoding]];
    }
}

- (void)processGyro:(CMGyroData*)gyroData withError:(NSError*)error
{
    if (self.logRawGyroscopeData) {
        NSString *rawGyroscopeString = [NSString stringWithFormat:@"%f,%f,%f,%f\n", gyroData.timestamp,
                                                   gyroData.rotationRate.x,
                                                   gyroData.rotationRate.y,
                                                   gyroData.rotationRate.z,
                                                   nil];
        [self.handleRawGyroscopeData writeData:[rawGyroscopeString dataUsingEncoding:NSUTF8StringEncoding]];
    }
}

- (void) processMotion:(CMDeviceMotion*)motion withError:(NSError*)error
{
    if (self.logAttitudeData) {
        NSString *attitudeString = [NSString stringWithFormat:@"%f,%f,%f,%f\n", motion.timestamp,
                                           motion.attitude.roll,
                                           motion.attitude.pitch,
                                           motion.attitude.yaw,
                                           nil];
        [self.handleAttitudeData writeData:[attitudeString dataUsingEncoding:NSUTF8StringEncoding]];
    }

    if (self.logGravityData) {
        NSString *gravityString = [NSString stringWithFormat:@"%f,%f,%f,%f\n", motion.timestamp,
                                         motion.gravity.x,
                                         motion.gravity.y,
                                         motion.gravity.z,
                                         nil];
        [self.handleGravityData writeData:[gravityString dataUsingEncoding:NSUTF8StringEncoding]];
    }

    if (self.logMagneticFieldData) {
        NSString *magneticFieldString = [NSString stringWithFormat:@"%f,%f,%f,%f,%d\n", motion.timestamp,
                                                     motion.magneticField.field.x,
                                                     motion.magneticField.field.y,
                                                     motion.magneticField.field.z,
                                                     (int)motion.magneticField.accuracy,
                                                     nil];
        [self.handleMagneticFieldData writeData:[magneticFieldString dataUsingEncoding:NSUTF8StringEncoding]];
    }

    if (self.logRotationRateData) {
        NSString *rotationRateString = [NSString stringWithFormat:@"%f,%f,%f,%f\n", motion.timestamp,
                                                   motion.rotationRate.x,
                                                   motion.rotationRate.y,
                                                   motion.rotationRate.z,
                                                   nil];
        
        [self.handleRotationRateData writeData:[rotationRateString dataUsingEncoding:NSUTF8StringEncoding]];
    }

    if (self.logUserAccelerationData) {
        NSString *userAccelerationString = [NSString stringWithFormat:@"%f,%f,%f,%f\n", motion.timestamp,
                                                           motion.userAcceleration.x,
                                                           motion.userAcceleration.y,
                                                           motion.userAcceleration.z,
                                                           nil];
        [self.handleUserAccelerationData writeData:[userAccelerationString dataUsingEncoding:NSUTF8StringEncoding]];
    }
}

+ (BOOL)nameExists:(NSString *)name
{
    return [[NSFileManager defaultManager] fileExistsAtPath:[[self applicationDocumentsDirectory] stringByAppendingPathComponent:name]];
}

- (void)setName:(NSString *)name
{
    _name = name;
    if (name.length) {
        self.folderPath = [[DataLogger applicationDocumentsDirectory] stringByAppendingPathComponent:name];
    }
}

@end
