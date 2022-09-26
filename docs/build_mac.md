BUILD MediaPipe for Mac

Build opencv 3.4.16
cmake -DCMAKE_OSX_DEPLOYMENT_TARGET=10.15 -DCMAKE_OSX_ARCHITECTURES="x86_64;arm64" -DCMAKE_BUILD_TYPE=Release -DBUILD_EXAMPLES=OFF ../
Make -j12

Fix build
Edit file …/external/cpuinfo/BUILD.bazel
Remove  "cpu": "darwin" in
 config_setting(
    name = "macos_x86_64",
    values = {
        "apple_platform_type": "macos",
        "cpu": "darwin",
    },
)

Same with external/XNNPACK/BUILD.bazel


Build lib: bazel build --macos_cpus=arm64,x86_64 --define MEDIAPIPE_DISABLE_GPU=1 mediapipe/mac_bundle:PSYBodyTracking
If error with numpy (already install but not found) using this command:
// Note /usr/local/bin/python3.9 is path of python3
bazel build --macos_cpus=arm64/x86_64 -c opt --define MEDIAPIPE_DISABLE_GPU=1 --action_env PYTHON_BIN_PATH=/usr/local/bin/python3.9 mediapipe/mac_bundle:PSYBodyTracking
