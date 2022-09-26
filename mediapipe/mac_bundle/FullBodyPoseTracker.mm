#import "FullBodyPoseTracker.h"
#import "MPPGraph.h"
#include "MyLib.h"

// #define REGISTER_CALCULATOR(name)                                          \
//   REGISTER_FACTORY_FUNCTION_QUALIFIED(::upipe::CalculatorBaseRegistry, \
//                                       calculator_registration, name,       \
//                                       absl::make_unique<name>);            \
//   REGISTER_FACTORY_FUNCTION_QUALIFIED(                                     \
//       ::upipe::internal::StaticAccessToCalculatorBaseRegistry,         \
//       access_registration, name,                                           \
//       absl::make_unique<                                                   \
//           ::upipe::internal::StaticAccessToCalculatorBaseTyped<name>>);     \
//   void register_##name(){typeid(name);};

#include "mediapipe/framework/formats/landmark.pb.h"
#import "MPPTimestampConverter.h"

static NSString* const kGraphName = @"holistic_tracking_cpu";
static const char* kInputStream = "input_video";
static const char* kOutputStream = "output_video";
static const char* kLandmarksOutputStream = "pose_landmarks";
static const char* kVideoQueueLabel = "com.google.mediapipe.example.videoQueue";
static const char* kHandLandmarksOutputStream = "hand_landmarks";
static const char* kNumHandsInputSidePacket = "num_hands";

@interface UpperBodyPoseTracker() <MPPGraphDelegate>
@property(nonatomic) MPPGraph* mediapipeGraph;
@property(nonatomic) MPPTimestampConverter *timestampConverter;
@end

@interface Landmark()
- (instancetype)initWithX:(float)x y:(float)y z:(float)z;
@end

@implementation UpperBodyPoseTracker {}

#pragma mark - Cleanup methods

- (void)dealloc {
    self.mediapipeGraph.delegate = nil;
    [self.mediapipeGraph cancel];
    // Ignore errors since we're cleaning up.
    [self.mediapipeGraph closeAllInputStreamsWithError:nil];
    [self.mediapipeGraph waitUntilDoneWithError:nil];
}

#pragma mark - MediaPipe graph methods

+ (MPPGraph*)loadGraphFromResource:(NSString*)resource {
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
    [newGraph addFrameOutputStream:kOutputStream outputPacketType:MPPPacketTypeImageFrame];
    [newGraph addFrameOutputStream:kLandmarksOutputStream outputPacketType:MPPPacketTypeRaw];
    return newGraph;
}

- (instancetype)init
{
    MyLib *ml = new MyLib();
    self = [super init];
    if (self) {
        self.mediapipeGraph = [[self class] loadGraphFromResource:kGraphName];
        self.mediapipeGraph.delegate = self;
        // Set maxFramesInFlight to a small value to avoid memory contention for real-time processing.
        self.mediapipeGraph.maxFramesInFlight = 0;
        self.timestampConverter = [[MPPTimestampConverter alloc] init];
    }
    return self;
}

- (void)startGraph {
    // Start running self.mediapipeGraph.
    NSError* error;
    if (![self.mediapipeGraph startWithError:&error]) {
        NSLog(@"Failed to start graph: %@", error);
        return;
    }

    NSLog(@"startGraph successful, limit: %d", self.mediapipeGraph.maxFramesInFlight);
}

#pragma mark - MPPGraphDelegate methods

// Receives CVPixelBufferRef from the MediaPipe graph. Invoked on a MediaPipe worker thread.
- (void)mediapipeGraph:(MPPGraph*)graph
  didOutputPixelBuffer:(CVPixelBufferRef)pixelBuffer
            fromStream:(const std::string&)streamName {
    NSLog(@"mediapipeGraph:didOutputPixelBuffer:fromStream %@", [NSString stringWithCString:streamName.c_str() 
                                   encoding:[NSString defaultCStringEncoding]]);
      if (streamName == kOutputStream) {
          [_delegate upperBodyPoseTracker: self didOutputPixelBuffer: pixelBuffer];
      }
}

// Receives a raw packet from the MediaPipe graph. Invoked on a MediaPipe worker thread.
- (void)mediapipeGraph:(MPPGraph*)graph
       didOutputPacket:(const ::mediapipe::Packet&)packet
            fromStream:(const std::string&)streamName {
    if (streamName == kLandmarksOutputStream) {
        if (packet.IsEmpty()) { return; }
        const auto& landmarks = packet.Get<::mediapipe::NormalizedLandmarkList>();
        
        //        for (int i = 0; i < landmarks.landmark_size(); ++i) {
        //            NSLog(@"\tLandmark[%d]: (%f, %f, %f)", i, landmarks.landmark(i).x(),
        //                  landmarks.landmark(i).y(), landmarks.landmark(i).z());
        //        }
        NSMutableArray<Landmark *> *result = [NSMutableArray array];
        for (int i = 0; i < landmarks.landmark_size(); ++i) {
            Landmark *landmark = [[Landmark alloc] initWithX:landmarks.landmark(i).x()
                                                           y:landmarks.landmark(i).y()
                                                           z:landmarks.landmark(i).z()];
            [result addObject:landmark];
        }
        [_delegate upperBodyPoseTracker: self didOutputLandmarks: result];
    }
}

-(BOOL)sendPixelBuffer:(CVPixelBufferRef)pixelBuffer timestamp:(CMTime)timestamp {
    return [self.mediapipeGraph sendPixelBuffer:pixelBuffer
                              intoStream:kInputStream
                              packetType:MPPPacketTypeImageFrameBGRANoSwap
                              timestamp:[self.timestampConverter timestampForMediaTime:timestamp]];
}

@end


@implementation Landmark

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
  return [NSString stringWithFormat:@"Landmark: (%.2f, %.2f, %.2f)", _x, _y, _z];
}

@end
