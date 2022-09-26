#import <Foundation/Foundation.h>
#import <CoreVideo/CoreVideo.h>
#import <CoreMedia/CoreMedia.h>

@class MPLandmark;
@class PSYBodyTracking;
@class MPRect;
@class MPNormalizedRect;
@class MPDetection;

@protocol PSYBodyTrackingDelegate <NSObject>
-(void)psyBodyTracking:(PSYBodyTracking*)tracking didOutputPixelBuffer:(CVPixelBufferRef)pixelBuffer;
-(void)psyBodyTracking:(PSYBodyTracking*)tracking didOutputPoseLandmarks:(NSArray<MPLandmark*> *)landmarks;
-(void)psyBodyTracking:(PSYBodyTracking*)tracking didOutputPoseDetect:(MPDetection *)detection;
-(void)psyBodyTracking:(PSYBodyTracking*)tracking didOutputHandLandmarks:(NSArray<MPLandmark*> *)landmarks isLeft:(BOOL)isLeft;
-(void)psyBodyTracking:(PSYBodyTracking*)tracking didOutputFaceLandmarks:(NSArray<MPLandmark*> *)landmarks;
@end

// typedef NS_OPTIONS(NSUInteger, PSYBodyTrackingOptions) {
//         PSYBodyTrackingNone			        =  0,
//         PSYBodyTrackingImageOutput  			=  1,
//         PSYBodyTrackingPoseLandmarks			=  2,
//         PSYBodyTrackingPoseDetect			=  4,
//         PSYBodyTrackingLeftHandLandmarks		=  8,
//         PSYBodyTrackingRightHandLandmarks		=  16,
//         PSYBodyTrackingFaceLandmarks			=  32,
// };

@interface PSYBodyTracking : NSObject
@property(weak, nonatomic) id<PSYBodyTrackingDelegate> delegate;
// @property(readwrite, nonatomic) PSYBodyTrackingOptions trackingOptions;

-(instancetype)init;
-(void)startGraphWantOutputImage:(BOOL)wantOutputImage callback:(void (^)(BOOL success))callback;
-(BOOL)sendPixelBuffer:(CVPixelBufferRef)pixelBuffer timestamp:(CMTime)timestamp;

@end

@interface MPLandmark : NSObject
@property(nonatomic, readonly) float x;
@property(nonatomic, readonly) float y;
@property(nonatomic, readonly) float z;
@end

@interface MPRect : NSObject
@property(nonatomic, readonly) NSInteger xCenter;
@property(nonatomic, readonly) NSInteger yCenter;
@property(nonatomic, readonly) NSInteger width;
@property(nonatomic, readonly) NSInteger height;
@end

@interface MPNormalizedRect : NSObject
@property(nonatomic, readonly) CGFloat xCenter;
@property(nonatomic, readonly) CGFloat yCenter;
@property(nonatomic, readonly) CGFloat width;
@property(nonatomic, readonly) CGFloat height;
@end

typedef NS_ENUM(NSUInteger, MPLocationDataFormat) {
    MPLocationDataFormatGlobals = 0,
    MPLocationDataFormatBoundingBox = 1,
    MPLocationDataFormatRelativeBoundingBox = 2,
    MPLocationDataFormatMASK = 3
};

@interface MPBoundingBox : NSObject
@property(nonatomic, assign) NSInteger xMin;
@property(nonatomic, assign) NSInteger yMin;
@property(nonatomic, assign) NSInteger width;
@property(nonatomic, assign) NSInteger height;
@end

@interface MPRelativeBoundingBox : NSObject
@property(nonatomic, assign) CGFloat xMin;
@property(nonatomic, assign) CGFloat yMin;
@property(nonatomic, assign) CGFloat width;
@property(nonatomic, assign) CGFloat height;
@end

@interface MPInterval: NSObject
@property(nonatomic, assign) NSInteger y;
@property(nonatomic, assign) NSInteger leftX;
@property(nonatomic, assign) NSInteger rightX;
@end

@interface MPRasterization : NSObject
@property(nonatomic, strong) NSArray<MPInterval *> *intervals;
@end

@interface MPBinaryMask : NSObject
@property(nonatomic, assign) NSInteger width;
@property(nonatomic, assign) NSInteger height;
@property(nonatomic, strong) MPRasterization *rasterization;
@end

@interface MPRelativeKeypoint : NSObject
@property(nonatomic, assign) CGFloat x;
@property(nonatomic, assign) CGFloat y;
@property(nonatomic, copy) NSString *keypointLabel;
@property(nonatomic, assign) CGFloat score;
@end

@interface MPLocationData : NSObject
@property(nonatomic, assign) MPLocationDataFormat format;
@property(nonatomic, strong) MPBoundingBox *boundingBox;
@property(nonatomic, strong) MPRelativeBoundingBox *relativeBoundingBox;
@property(nonatomic, strong) MPBinaryMask *mask;
@property(nonatomic, strong) MPRelativeKeypoint *relativeKeypoints;
@end

@interface MPAssociatedDetection : NSObject
@property(nonatomic, assign) NSInteger adId;
@property(nonatomic, assign) CGFloat confidence;
@end

@interface MPDetection : NSObject
@property(nonatomic, strong) NSArray<NSString *> *labels;
@property(nonatomic, strong) NSArray<NSNumber *> *labelIds;
@property(nonatomic, strong) NSArray<NSNumber *> *scores;
@property(nonatomic, strong) MPLocationData *locationData;
@property(nonatomic, copy) NSString *featureTag;
@property(nonatomic, copy) NSString *trackId;
@property(nonatomic, assign) NSInteger detectionId;
@property(nonatomic, strong) NSArray<MPAssociatedDetection *> *associatedDetections;
@property(nonatomic, strong) NSArray<NSString *> *displayNames;
@property(nonatomic, assign) NSInteger timestampUsec;
@end

@interface MPDetectionList : NSObject
@property(nonatomic, strong) NSArray<MPDetection *> *detections;
@end
