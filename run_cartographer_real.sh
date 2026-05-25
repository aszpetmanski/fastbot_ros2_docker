#!/usr/bin/env bash
set -eo pipefail

source /opt/ros/humble/setup.bash
source /ros2_ws/install/setup.bash

RUNTIME_DIR="${RUNTIME_DIR:-/tmp/fastbot_slam_runtime}"
CONFIG_DIR="$RUNTIME_DIR/config"
LUA_FILE="$CONFIG_DIR/cartographer.lua"

mkdir -p "$CONFIG_DIR"

PKG_SHARE="$(ros2 pkg prefix fastbot_slam)/share/fastbot_slam"

cp "$PKG_SHARE/config/cartographer.lua" "$LUA_FILE"

export CARTOGRAPHER_LUA="$LUA_FILE"
export CARTOGRAPHER_CONFIG_DIR="$CONFIG_DIR"

python3 - <<'PY'
import os
import re
import pathlib

lua = pathlib.Path(os.environ["CARTOGRAPHER_LUA"])
text = lua.read_text()

def set_string(key, value):
    global text
    text = re.sub(
        rf'({key}\s*=\s*)"[^"]*"',
        rf'\1"{value}"',
        text,
    )

def set_bool(key, value):
    global text
    value = "true" if str(value).lower() in ("1", "true", "yes", "on") else "false"
    text = re.sub(
        rf'({key}\s*=\s*)(true|false)',
        rf'\1{value}',
        text,
    )

set_string("tracking_frame", os.environ.get("TRACKING_FRAME", "base_link"))
set_string("published_frame", os.environ.get("PUBLISHED_FRAME", "base_link"))
set_string("odom_frame", os.environ.get("ODOM_FRAME", "fastbot_odom"))

set_bool("use_odometry", os.environ.get("USE_ODOMETRY", "true"))
set_bool("provide_odom_frame", os.environ.get("PROVIDE_ODOM_FRAME", "true"))

lua.write_text(text)
PY

cat > "$RUNTIME_DIR/cartographer_real.launch.py" <<'PY'
from launch import LaunchDescription
from launch_ros.actions import Node
import os

def env_bool(name, default=False):
    value = os.environ.get(name, str(default)).lower()
    return value in ("1", "true", "yes", "on")

def generate_launch_description():
    config_dir = os.environ.get(
        "CARTOGRAPHER_CONFIG_DIR",
        "/tmp/fastbot_slam_runtime/config",
    )

    return LaunchDescription([
        Node(
            package="cartographer_ros",
            executable="cartographer_node",
            name="cartographer_node",
            output="screen",
            parameters=[{
                "use_sim_time": env_bool("USE_SIM_TIME", False)
            }],
            arguments=[
                "-configuration_directory", config_dir,
                "-configuration_basename", "cartographer.lua",
            ],
            remappings=[
                ("odom", os.environ.get("ODOM_TOPIC", "/fastbot/odom")),
                ("scan", os.environ.get("SCAN_TOPIC", "/scan")),
            ],
        ),

        Node(
            package="cartographer_ros",
            executable="cartographer_occupancy_grid_node",
            name="occupancy_grid_node",
            output="screen",
            parameters=[{
                "use_sim_time": env_bool("USE_SIM_TIME", False)
            }],
            arguments=[
                "-resolution", os.environ.get("MAP_RESOLUTION", "0.05"),
                "-publish_period_sec", os.environ.get("MAP_PUBLISH_PERIOD", "1.0"),
            ],
        ),
    ])
PY

echo
echo "--- patched cartographer.lua ---"
grep -nE "tracking_frame|published_frame|odom_frame|provide_odom_frame|use_odometry" "$LUA_FILE"

echo
echo "--- visible ROS topics ---"
ros2 topic list | grep -E "(/fastbot/odom|/scan|/map|/tf|/tf_static|/clock)" || true

echo
echo "--- launching Cartographer real robot SLAM ---"
exec ros2 launch "$RUNTIME_DIR/cartographer_real.launch.py"
