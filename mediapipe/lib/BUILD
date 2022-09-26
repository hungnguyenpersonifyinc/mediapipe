load("@build_bazel_rules_apple//apple:macos.bzl", "macos_dylib")

macos_dylib(
    name = "mediapipe",
    minimum_os_version = "10.15",
    deps = [
     ":mediapipe_framework",
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

