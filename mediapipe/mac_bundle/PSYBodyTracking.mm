#import "PSYBodyTracking.h"
#import "MPPGraph.h"

#include "mediapipe/framework/formats/landmark.pb.h"
#include "mediapipe/framework/formats/rect.pb.h"
#include "mediapipe/framework/formats/detection.pb.h"
#include "mediapipe/framework/formats/location_data.pb.h"
#import "MPPTimestampConverter.h"

#define OptionsHasValue(options, value) (((options) & (value)) == (value))

static const char* kVideoQueueLabel = "com.google.mediapipe.example.videoQueue";

static NSString* const kGraphName = @"holistic_tracking_cpu";
static const char* kInputStream = "input_video";
static const char* kOutputStream = "output_video";
static const char* kPoseLandmarksOutputStream = "pose_landmarks";
static const char* kPoseDetectionOutputStream = "pose_detection";

static const char* kLeftHandLandmarksOutputStream = "left_hand_landmarks";
static const char* kRightHandLandmarksOutputStream = "right_hand_landmarks";
static const char* kFaceLandmarksOutputStream = "face_landmarks";
static const char* kNumHandsInputSidePacket = "num_hands";

@interface PSYBodyTracking() <MPPGraphDelegate>
@property(nonatomic) MPPGraph* mediapipeGraph;
@property(nonatomic) MPPTimestampConverter *timestampConverter;
@end

@interface MPLandmark()
- (instancetype)initWithX:(float)x y:(float)y z:(float)z;
@end

@interface MPRect()

- (instancetype)initWithXCenter:(NSInteger)xCenter
                        yCenter:(NSInteger)yCenter
                          width:(NSInteger)width
                         height:(NSInteger)height;
@end

@interface MPNormalizedRect()

- (instancetype)initWithXCenter:(CGFloat)xCenter
                        yCenter:(CGFloat)yCenter
                          width:(CGFloat)width
                         height:(CGFloat)height;

@end

@interface MPDetection()

- (void)detectFrom:(const mediapipe::Detection &)detection;

@end

@implementation PSYBodyTracking
@synthesize trackingOptions = _trackingOptions;

#pragma mark - Cleanup methods

- (void)stop {
    self.mediapipeGraph.delegate = nil;
    [self.mediapipeGraph cancel];
    // Ignore errors since we're cleaning up.
    [self.mediapipeGraph closeAllInputStreamsWithError:nil];
    [self.mediapipeGraph waitUntilDoneWithError:nil];
}

- (void)dealloc {
    [self stop];
}

#pragma mark - MediaPipe graph methods

+ (MPPGraph*)loadGraphFromResource:(NSString*)resource options:(PSYBodyTrackingOptions)trackingOptions {
    // Load the graph config resource.
    NSError* configLoadError = nil;
    NSBundle* bundle = [NSBundle bundleForClass:[self class]];
    if (!resource || resource.length == 0) {
        return nil;
    }
    NSURL* graphURL = [bundle URLForResource:resource withExtension:@"binarypb"];
    NSData* data = [NSData dataWithContentsOfURL:graphURL options:0 error:&configLoadError];
    if (!data) {
        NSLog(@"Failed to load MediaPipe graph config: %@", configLoadError);
        return nil;
    }
    
    // Parse the graph config resource into mediapipe::CalculatorGraphConfig proto object.
    mediapipe::CalculatorGraphConfig config;
    config.ParseFromArray(data.bytes, data.length);
    
    // Create MediaPipe graph with mediapipe::CalculatorGraphConfig proto object.
    MPPGraph* newGraph = [[MPPGraph alloc] initWithGraphConfig:config];
    
    if (OptionsHasValue(trackingOptions, PSYBodyTrackingPoseLandmarks)) {
        [newGraph addFrameOutputStream:kPoseLandmarksOutputStream outputPacketType:MPPPacketTypeRaw];
    }

    if (OptionsHasValue(trackingOptions, PSYBodyTrackingPoseDetect)) {
        [newGraph addFrameOutputStream:kPoseDetectionOutputStream outputPacketType:MPPPacketTypeRaw];
    }

    if (OptionsHasValue(trackingOptions, PSYBodyTrackingLeftHandLandmarks)) {
        [newGraph addFrameOutputStream:kLeftHandLandmarksOutputStream outputPacketType:MPPPacketTypeRaw];
    }

    if (OptionsHasValue(trackingOptions, PSYBodyTrackingRightHandLandmarks)) {
        [newGraph addFrameOutputStream:kRightHandLandmarksOutputStream outputPacketType:MPPPacketTypeRaw];
    }

    if (OptionsHasValue(trackingOptions, PSYBodyTrackingFaceLandmarks)) {
        [newGraph addFrameOutputStream:kFaceLandmarksOutputStream outputPacketType:MPPPacketTypeRaw];
    }

    if (OptionsHasValue(trackingOptions, PSYBodyTrackingImageOutput)) {
        [newGraph addFrameOutputStream:kOutputStream outputPacketType:MPPPacketTypeImageFrame];
    }

    return newGraph;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        
    }
    return self;
}

- (void)loadGraph {
    self.mediapipeGraph = [[self class] loadGraphFromResource:kGraphName options:_trackingOptions];
    self.mediapipeGraph.delegate = self;
    // Set maxFramesInFlight to a small value to avoid memory contention for real-time processing.
    self.mediapipeGraph.maxFramesInFlight = 0;
    if (self.timestampConverter) {
        [self.timestampConverter reset];
    } else {
        self.timestampConverter = [[MPPTimestampConverter alloc] init];
    }
}

-(void)startGraphWithCallback:(void (^)(BOOL success))callback {
    PSYBodyTracking *__weak weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        @autoreleasepool {
            [weakSelf stop];
            [weakSelf loadGraph];

            // Start running self.mediapipeGraph.
            NSError* error;
            if (![weakSelf.mediapipeGraph startWithError:&error]) {
                NSLog(@"Failed to start graph: %@", error);
                callback(false);
            } else {
                callback(true);
            }

            [weakSelf.timestampConverter reset];
        }
    });
}

- (void)removeAllOutput {
    [self.mediapipeGraph closeAllInputStreamsWithError:nil];
}

 - (void)setTrackingOptions:(PSYBodyTrackingOptions)trackingOptions {
     _trackingOptions = trackingOptions;
     [self removeAllOutput];
     [self.timestampConverter reset];
 }

 - (PSYBodyTrackingOptions)trackingOptions {
     return _trackingOptions;
 }

#pragma mark - MPPGraphDelegate methods

// Receives CVPixelBufferRef from the MediaPipe graph. Invoked on a MediaPipe worker thread.
- (void)mediapipeGraph:(MPPGraph*)graph
  didOutputPixelBuffer:(CVPixelBufferRef)pixelBuffer
            fromStream:(const std::string&)streamName {
      if (streamName == kOutputStream) {
          [_delegate psyBodyTracking: self didOutputPixelBuffer: pixelBuffer];
      }
}

// Receives a raw packet from the MediaPipe graph. Invoked on a MediaPipe worker thread.
- (void)mediapipeGraph:(MPPGraph*)graph
       didOutputPacket:(const ::mediapipe::Packet&)packet
            fromStream:(const std::string&)streamName {

    if (streamName == kPoseLandmarksOutputStream) {
        [self didOutputPoseLandmarksPackage: packet];
        return;
    }

    if (streamName == kPoseDetectionOutputStream) {
        [self didOutputPoseDetectPackage: packet];
        return;
    }

    if (streamName == kLeftHandLandmarksOutputStream) {
        [self didOutputHandLandmarksPackage: packet isLeftHand: true];
        return;
    }

    if (streamName == kRightHandLandmarksOutputStream) {
        [self didOutputHandLandmarksPackage: packet isLeftHand: true];
        return;
    }

    if (streamName == kFaceLandmarksOutputStream) {
        [self didOutputFaceLandmarksPackage: packet];
        return;
    }
}

- (void)didOutputPoseLandmarksPackage:(const ::mediapipe::Packet&)packet {
    if (packet.IsEmpty()) { return; }
    const auto& landmarks = packet.Get<::mediapipe::NormalizedLandmarkList>();
    
    NSMutableArray<MPLandmark *> *result = [NSMutableArray array];
    for (int i = 0; i < landmarks.landmark_size(); ++i) {
        MPLandmark *landmark = [[MPLandmark alloc] initWithX:landmarks.landmark(i).x()
                                                        y:landmarks.landmark(i).y()
                                                        z:landmarks.landmark(i).z()];
        [result addObject:landmark];
    }
    [_delegate psyBodyTracking:self didOutputPoseLandmarks:result];
}

- (void)didOutputPoseDetectPackage:(const ::mediapipe::Packet&)packet {
    if (packet.IsEmpty()) { return; }
    const auto& roi = packet.Get<::mediapipe::Detection>();
    MPDetection *detection = [[MPDetection alloc] init];
    [detection detectFrom: roi];
    [_delegate psyBodyTracking: self didOutputPoseDetect:detection];
}

- (void)didOutputHandLandmarksPackage:(const ::mediapipe::Packet&)packet isLeftHand:(BOOL)isLeftHand {
    if (packet.IsEmpty()) { return; }
    const auto& landmarks = packet.Get<::mediapipe::NormalizedLandmarkList>();

    NSMutableArray<MPLandmark *> *result = [NSMutableArray array];
    for (int i = 0; i < landmarks.landmark_size(); ++i) {
        MPLandmark *landmark = [[MPLandmark alloc] initWithX:landmarks.landmark(i).x()
                                                           y:landmarks.landmark(i).y()
                                                           z:landmarks.landmark(i).z()];
        [result addObject:landmark];
    }
    [_delegate psyBodyTracking: self didOutputHandLandmarks: result isLeft: isLeftHand];
}

- (void)didOutputFaceLandmarksPackage:(const ::mediapipe::Packet&)packet {
    if (packet.IsEmpty()) { return; }
    const auto& landmarks = packet.Get<::mediapipe::NormalizedLandmarkList>();

    NSMutableArray<MPLandmark *> *result = [NSMutableArray array];
    for (int i = 0; i < landmarks.landmark_size(); ++i) {
        MPLandmark *landmark = [[MPLandmark alloc] initWithX:landmarks.landmark(i).x()
                                                           y:landmarks.landmark(i).y()
                                                           z:landmarks.landmark(i).z()];
        [result addObject:landmark];
    }
    [_delegate psyBodyTracking: self didOutputFaceLandmarks:result];
}

-(BOOL)sendPixelBuffer:(CVPixelBufferRef)pixelBuffer timestamp:(CMTime)timestamp {
    return [self.mediapipeGraph sendPixelBuffer:pixelBuffer
                              intoStream:kInputStream
                              packetType:MPPPacketTypeImageFrame
                              timestamp:[self.timestampConverter timestampForMediaTime:timestamp]];
}

@end


@implementation MPLandmark

- (instancetype)initWithX:(float)x y:(float)y z:(float)z
{
    self = [super init];
    if (self) {
        _x = x;
        _y = y;
        _z = z;
    }
    return self;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"MPLandmark: (%.2f, %.2f, %.2f)", _x, _y, _z];
}

@end

@implementation MPRect

- (instancetype)initWithXCenter:(NSInteger)xCenter yCenter:(NSInteger)yCenter width:(NSInteger)width height:(NSInteger)height
{
    self = [super init];
    if (self) {
        _xCenter = xCenter;
        _yCenter = yCenter;
        _width = width;
        _height = height;
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"MPRect: (%d, %d, %d, %d)", _xCenter, _yCenter, _width, _height];
}

@end

@implementation MPNormalizedRect

- (instancetype)initWithXCenter:(CGFloat)xCenter yCenter:(CGFloat)yCenter width:(CGFloat)width height:(CGFloat)height
{
    self = [super init];
    if (self) {
        _xCenter = xCenter;
        _yCenter = yCenter;
        _width = width;
        _height = height;
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"MPNormalizedRect: (%.2f, %.2f, %.2f, %.2f)", _xCenter, _yCenter, _width, _height];
}

@end

@implementation MPBoundingBox : NSObject

@end

@implementation MPRelativeBoundingBox : NSObject

@end

@implementation MPInterval: NSObject

@end

@implementation MPRasterization : NSObject

@end

@implementation MPBinaryMask : NSObject

@end

@implementation MPRelativeKeypoint : NSObject

@end

@implementation MPLocationData : NSObject

@end

@implementation MPAssociatedDetection : NSObject
@end

@implementation MPDetection : NSObject
- (void)detectFrom:(const mediapipe::Detection &)detection {
    
}

@end

@implementation MPDetectionList : NSObject
@end