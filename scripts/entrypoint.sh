#!/bin/sh
set -e
echo "10.0.0.8  scitos" >> /etc/hosts
echo "10.0.0.239  SATELLITE-S50-B" >> /etc/hosts
echo "172.28.5.2 tsn_denseflow" >> /etc/hosts
echo "192.168.0.11 poop" >> /etc/hosts
echo "history -s /tmp/start.sh " >> /root/.bashrc

#bash  /root/face_recognition/catkin_ws.sh
export ROS_MASTER_URI=http://poop:11311
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/conda/lib
export ROS_IP=`hostname -I`
export ROS_HOSTNAME=`hostname -I`

service ssh restart
cat /root/banner.txt
exec "$@"
