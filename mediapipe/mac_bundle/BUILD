load("@build_bazel_rules_apple//apple:macos.bzl", "macos_bundle")

macos_bundle(
    name = "PSYBodyTracking",
    bundle_id = "dev.noppe.HandTracker",
    infoplists = ["Info.plist"],
    minimum_os_version = "10.15",
    deps = [
        ":CommonAppLibrary",
    ],
)

cc_library(
    name = "CFHolder",
    # Header is excluded on non-ios so you can still build :all.
    hdrs = select({
        "//mediapipe:apple": ["CFHolder.h"],
        "//conditions:default": [],
    }),
    features = ["layering_check"],
    visibility = ["//mediapipe/framework:mediapipe_internal"],
)

cc_library(
    name = "util",
    srcs = ["util.cc"],
    hdrs = ["util.h"],
    features = [
        "-parse_headers",
        "layering_check",
    ],
    
    linkopts = [
        "-framework Accelerate",
        "-framework CoreFoundation",
        "-framework CoreGraphics",
        "-framework CoreVideo",
    ],
    
    visibility = ["//mediapipe/framework:mediapipe_internal"],
    deps = [
        ":CFHolder",
        "//mediapipe/framework:packet",
        "//mediapipe/framework/formats:image_frame",
        "//mediapipe/framework/port:logging",
        "//mediapipe/framework/port:ret_check",
        "//mediapipe/framework/port:source_location",
        "//mediapipe/framework/port:status",
    ],
)

cc_library(
    name = "mediapipe_framework",
    linkopts = select({
        "//conditions:default": [],
    }),
    visibility = ["//visibility:public"],
    deps = [
        "//mediapipe/framework:calculator_framework",
        "//mediapipe/framework/tool:calculator_graph_template_cc_proto",
        "//mediapipe/framework/port:logging",
        "//mediapipe/framework/formats:classification_cc_proto",
        "//mediapipe/framework/formats:landmark_cc_proto",
        "//mediapipe/framework/formats:detection_cc_proto",
        "//mediapipe/framework/formats:rect_cc_proto",

    ]  + select({
        "//conditions:default": [
            "//mediapipe/graphs/hand_tracking:mobile_calculators",
           "//mediapipe/graphs/object_detection:mobile_calculators",
        ],
    
        "//mediapipe/gpu:disable_gpu": [
            "//mediapipe/graphs/hand_tracking:desktop_tflite_calculators",
            "//mediapipe/graphs/object_detection:desktop_tflite_calculators",
        ],
    }),
    alwayslink = 1,
)

objc_library(
    name = "hand_tracking_cpu",
    data = [
        "//mediapipe/modules/hand_landmark:hand_landmark_full.tflite",
        "//mediapipe/modules/palm_detection:palm_detection_full.tflite",
        "//mediapipe/graphs/hand_tracking:hand_tracking_desktop_live.binarypb",
        "//mediapipe/modules/hand_landmark:handedness.txt",
    ],
    deps = [
        "//mediapipe/graphs/hand_tracking:desktop_tflite_calculators",
    ],
)

objc_library(
    name = "CommonAppLibrary",
    srcs = [
        "FullBodyPoseTracker.mm",
        "MPPInputSource.mm",
        "MPPGraph.mm",
        "NSError+util_status.mm",
        "MPPTimestampConverter.mm",
        "MyLib.cc",
    ],
    hdrs = [
        "FullBodyPoseTracker.h",
        "MPPInputSource.h",
        "MPPGraph.h",
        "NSError+util_status.h",
        "MPPTimestampConverter.h",
        "MyLib.h",
    ],
    
    sdk_frameworks = [
        "AVFoundation",
        "CoreGraphics",
        "CoreMedia",
        "AppKit",
    ],
    
    copts = ["-std=c++17"],
    
    data = [ 
        "//mediapipe/graphs/holistic_tracking:holistic_tracking_cpu.binarypb",
        "//mediapipe/graphs/pose_tracking:pose_tracking_cpu.binarypb",
        "//mediapipe/modules/pose_detection:pose_detection.tflite",
        "//mediapipe/modules/pose_landmark:pose_landmark_full.tflite",
        "//mediapipe/graphs/hand_tracking:desktop_tflite_calculators",
        "//mediapipe/modules/holistic_landmark:hand_recrop.tflite",
    ],
    
    deps = [
        ":CFHolder",
        ":util",
        ":hand_tracking_cpu",
        ":mediapipe_framework",
        "//mediapipe/framework:calculator_framework",
    #    "//mediapipe/calculators/image:recolor_calculator",
        "//mediapipe/framework:mediapipe_profiling",
        "//mediapipe/framework/formats:image",
        "//mediapipe/framework/port:map_util",
        "//mediapipe/framework/port:ret_check",
        "//mediapipe/framework/port:source_location",
        "//mediapipe/framework/port:status",
        "//mediapipe/framework/port:statusor",
        "//mediapipe/framework/port:threadpool",
        "@com_google_absl//absl/base:core_headers",
        "@com_google_absl//absl/memory",
        "//mediapipe/util:cpu_util",
        "@com_google_absl//absl/strings",
        "@com_google_absl//absl/synchronization",
        "@google_toolbox_for_mac//:GTM_Defines",
        "//mediapipe/graphs/pose_tracking:pose_tracking_cpu_deps",
        "//mediapipe/graphs/holistic_tracking:holistic_tracking_cpu_graph_deps",
        "//mediapipe/framework/formats:landmark_cc_proto",
    ] + select({
        "//mediapipe:macos": [],
        "//conditions:default": [
            
        ],
    }),
)