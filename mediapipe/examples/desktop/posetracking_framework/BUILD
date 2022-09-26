# Copyright 2020 The MediaPipe Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

load(
    "@build_bazel_rules_apple//apple:macos.bzl",
    "macos_dylib",
)

load("//mediapipe/framework/tool:mediapipe_graph.bzl", "mediapipe_binary_graph")

macos_dylib(
    name = "PoseTrackingGpuApp",
    bundle_id = "dev.noppe.HandTracker",
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
    name = "CommonAppLibrary",
    srcs = [
        "FullBodyPoseTracker.mm",
        "MPPInputSource.mm",
        "MPPGraph.mm",
        "NSError+util_status.mm",
        "MPPCameraInputSource.mm",
        "MyLib.cc",
    ],
    hdrs = [
        "FullBodyPoseTracker.h",
        "MPPInputSource.h",
        "MPPGraph.h",
        "NSError+util_status.h",
        "MPPCameraInputSource.h",
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
        "//mediapipe/graphs/pose_tracking:pose_tracking_cpu.binarypb",
        "//mediapipe/modules/pose_detection:pose_detection.tflite",
        "//mediapipe/modules/pose_landmark:pose_landmark_full.tflite",
        "//mediapipe/graphs/hand_tracking:desktop_tflite_calculators",
    ],
    
    deps = [
        ":CFHolder",
        ":util",
        ":mediapipe_framework",
       # "//mediapipe/examples/ios/common:CommonMediaPipeAppLibrary",
       "//mediapipe/framework:calculator_framework",
       "//mediapipe/calculators/image:recolor_calculator",
        "//mediapipe/framework:mediapipe_profiling",
        "//mediapipe/framework/formats:image",
        "//mediapipe/framework/port:map_util",
        "//mediapipe/framework/port:ret_check",
        "//mediapipe/framework/port:source_location",
        "//mediapipe/framework/port:status",
        "//mediapipe/framework/port:statusor",
        "//mediapipe/framework/port:threadpool",
        # "//mediapipe/gpu:MPPGraphGPUData",
        # "//mediapipe/gpu:gl_base",
        # "//mediapipe/gpu:gpu_buffer",
        # "//mediapipe/gpu:gpu_shared_data_internal",
        # "//mediapipe/gpu:graph_support",
        # "//mediapipe/gpu:pixel_buffer_pool_util",
        "@com_google_absl//absl/base:core_headers",
        "@com_google_absl//absl/memory",
        "//mediapipe/util:cpu_util",
        "@com_google_absl//absl/strings",
        "@com_google_absl//absl/synchronization",
        "@google_toolbox_for_mac//:GTM_Defines",
        "//mediapipe/graphs/pose_tracking:pose_tracking_cpu_deps",
        "//mediapipe/framework/formats:landmark_cc_proto",
    ] + select({
        "//mediapipe:macos": [],
        "//conditions:default": [
            
        ],
    }),
)


mediapipe_binary_graph(
    name = "pose_tracking_cpu_binary_graph",
    graph = "pose_tracking_cpu.pbtxt",
    output_name = "pose_tracking_cpu.binarypb",
    deps = [":pose_tracking_cpu_deps"],
)
