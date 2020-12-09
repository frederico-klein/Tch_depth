#!/usr/bin/env bash

set -e

echo simple test

source ~/ros_catkin_ws/install_isolated/setup.bash

{
  echo "import cv2;import torch;import rospy" | python3
  echo "PASSED.\ncv2, torch and rospy can be imported into python3!"
} ||
{
echo "Import failed. Problems with either opencv, pytorch, ros/rospy or python3 installation!! "
}
