README.md
# FastBot ROS 2 — Docker Deployment (Simulation and Real Robot)

This repository contains Docker-based setups for:

- **Simulation**
- **Real robot**

The project can be run directly from published Docker images using `docker-compose`, without rebuilding locally.

Repository:

```bash
git clone https://github.com/aszpetmanski/fastbot_ros2_docker.git
```

Repository structure

After cloning, the relevant directories are:

ros2_ws/src/fastbot_ros2_docker/simulation — simulation setup
ros2_ws/src/fastbot_ros2_docker/real — real robot setup

# 1. Download the repository

Clone the repository on the target machine:
```bash
git clone https://github.com/aszpetmanski/fastbot_ros2_docker.git
cd fastbot_ros2_docker
```
This repository must be available both:

on the host used for simulation
on the robot computer for the real robot setup
# 2. General requirements
Docker and Docker Compose

Both simulation and real robot setups require:

Docker
Docker Compose

Install them with:
```bash
sudo apt-get update
sudo apt-get install -y docker.io docker-compose
sudo service docker start
```
Check versions:
```bash
docker --version
docker-compose --version
```
Optional: allow Docker without sudo:
```bash
sudo usermod -aG docker $USER
newgrp docker
```
Verify:
```bash
docker ps
docker-compose version
```
If this does not work immediately, log out and log back in.

# 3. Simulation setup

Go to the simulation directory:
```bash
cd ~/fastbot_ros2_docker/ros2_ws/src/fastbot_ros2_docker/simulation
```
Simulation requirements

## Before running the simulation stack, make sure the host has:

- Docker installed
- Docker Compose installed
- X11 enabled for GUI applications
- a running graphical session
- DISPLAY set
- access to the repository directory
- Enable X11 for Gazebo

Gazebo needs access to the host X server.

Allow local Docker containers to access X11:
```bash
xhost +local:docker
```
Check display:
```bash
echo $DISPLAY
```
Typical value:

:0

If DISPLAY is empty, Gazebo will not open on screen.

Pull simulation images
```bash
docker-compose pull
```
Create a network
```bash
docker network create fastbot-net
```

Start the simulation stack
```bash
docker-compose up
```
Detached mode:
```bash
docker-compose up -d
```
This starts:

- fastbot-ros2-gazebo
- fastbot-ros2-slam
- fastbot-ros2-webapp

## Exposed ports

The web application exposes:

7000:80
9090:9090

So the frontend should be available at:

http://localhost:7000

## Useful commands for simulation

List running containers:
```bash
docker ps
```
Open a shell inside the Gazebo container:
```bash
docker exec -it fastbot-ros2-gazebo bash
```
Open a shell inside the SLAM container:
```bash
docker exec -it fastbot-ros2-slam bash
```
Open a shell inside the WebApp container:
```bash
docker exec -it fastbot-ros2-webapp bash
```
## Control the simulated robot

Enter the Gazebo container:
```bash
docker exec -it fastbot-ros2-gazebo bash
```
Run teleoperation:
```bash
ros2 run teleop_twist_keyboard teleop_twist_keyboard --ros-args --remap cmd_vel:=/fastbot/cmd_vel
```
Publish /cmd_vel manually

Inside a ROS 2 container:
```bash
ros2 topic pub --once /fastbot/cmd_vel geometry_msgs/msg/Twist \
"{linear: {x: 0.2, y: 0.0, z: 0.0}, angular: {x: 0.0, y: 0.0, z: 0.0}}"
```
Rotation example:
```bash
ros2 topic pub --once /fastbot/cmd_vel geometry_msgs/msg/Twist \
"{linear: {x: 0.0, y: 0.0, z: 0.0}, angular: {x: 0.0, y: 0.0, z: 0.5}}"
```
Debugging simulation

Logs for all services:
```bash
docker-compose logs
```
Follow logs live:
```bash
docker-compose logs -f
```
One service only:
```bash
docker-compose logs -f fastbot-ros2-gazebo
docker-compose logs -f fastbot-ros2-slam
docker-compose logs -f fastbot-ros2-webapp
```
Check ROS topics:
```bash
docker exec -it fastbot-ros2-gazebo bash
ros2 topic list
```
Check if /cmd_vel exists:
```bash
ros2 topic list | grep cmd_vel
```
Check odometry:
```bash
ros2 topic echo /fastbot/odom
```
Stop simulation
```bash
docker-compose down
```
Remove volumes too:
```bash
docker-compose down -v
```
Restart simulation
```bash
docker-compose down
docker-compose up
```
Or detached:
```bash
docker-compose down
docker-compose up -d
```
# 4. Real robot setup

Go to the real robot directory:
```bash
cd ~/fastbot_ros2_docker/ros2_ws/src/fastbot_ros2_docker/real
```
Real robot requirements

On the robot computer, the following are required:

- Docker installed
- Docker Compose installed
- access to the repository
- network connectivity
- hardware devices available:
- - /dev/ttyUSB0
- - /dev/ttyACM0
- - /dev/video0

## The real robot setup uses two Docker images:

- alanszpetmanski/alan.szpetmanski-cp22:fastbot-ros2-real
- alanszpetmanski/alan.szpetmanski-cp22:fastbot-ros2-slam-real

## Container roles

### The real robot stack is split into two containers:

## Bringup container
- accesses the robot hardware
- starts the robot drivers
- publishes robot topics such as lidar, camera, odometry, TF, etc.
## Slam container
- does not access hardware directly
- subscribes to ROS 2 topics from the bringup container
- runs the SLAM stack

Because of this separation, the SLAM container does not need direct access to /dev/ttyUSB0, /dev/ttyACM0, or /dev/video0.

# Pull real robot images
```bash
docker-compose pull
```
Start the real robot stack
```bash
docker-compose up
```
Detached mode:
```bash
docker-compose up -d
```
This starts:

fastbot-bringup
fastbot-slam
Check that containers are running
```bash
docker ps
```
Expected containers:

fastbot-bringup
fastbot-slam
Check that robot topics are available

Run on the robot computer:
```bash
ros2 topic list
```
The output should include at least:

a laser topic, for example:
/scan
a camera topic, for example:
/fastbot/image_raw
a velocity command topic, for example:
/fastbot/cmd_vel

Other expected topics may include:

/fastbot/odom
/tf
/tf_static
/map
Useful commands for real robot

See running containers:
```bash
docker ps
```
See logs:
```bash
docker-compose logs
docker-compose logs -f
```
Logs for one container:
```bash
docker-compose logs -f bringup
docker-compose logs -f slam
```
Enter the bringup container:
```bash
docker exec -it fastbot-bringup bash
```
Enter the slam container:
```bash
docker exec -it fastbot-slam bash
```
Check topics inside a container:
```bash
ros2 topic list
```
Manual teleoperation test on the real robot

On the robot computer or on an external computer correctly connected to the robot ROS 2 network:
```bash
ros2 run teleop_twist_keyboard teleop_twist_keyboard --ros-args --remap cmd_vel:=/fastbot/cmd_vel
```
You can also publish a single velocity command manually:
```bash
ros2 topic pub --once /fastbot/cmd_vel geometry_msgs/msg/Twist \
"{linear: {x: 0.1, y: 0.0, z: 0.0}, angular: {x: 0.0, y: 0.0, z: 0.0}}"
```
# 5. Automatic startup when the robot is powered on

The real robot containers are configured to start automatically on boot using a systemd service.

This means that after turning the robot off and turning it back on again, the Docker containers should start automatically without needing to run docker-compose up manually.

Enable the service

On the robot computer:
```bash
sudo cp fastbot-compose.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable fastbot-compose.service
sudo systemctl start fastbot-compose.service
```
Check service status
```bash
systemctl status fastbot-compose.service
```
Verify automatic startup after reboot
Turn off the robot
Turn it back on
Log into the robot computer
Check:
```bash
docker ps
ros2 topic list
```
The expected result is:

fastbot-bringup is running
fastbot-slam is running
robot topics such as /scan, /fastbot/image_raw, and /fastbot/cmd_vel are available

# 6. External computer access to the robot topics

An external computer can connect to the robot topics over the network.

Requirements on the external computer

## The external computer must have:

- Ubuntu 22.04
- ROS 2 Humble installed
- Cyclone DDS installed
- network connectivity to the robot
- the same ROS 2 communication settings as the robot
- Required environment variables

The following values must match between the robot and the external computer:

- ROS_DOMAIN_ID
- RMW_IMPLEMENTATION

The external computer must also have:

- ROS_LOCALHOST_ONLY=0

Recommended setup:
```bash
source /opt/ros/humble/setup.bash
export ROS_DOMAIN_ID=0
export ROS_LOCALHOST_ONLY=0
export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp
```
Verify topic visibility from the external computer

Run:
```bash
ros2 topic list
```
You should be able to see the robot topics, including:

/scan
/fastbot/image_raw
/fastbot/cmd_vel
/map
/tf
Network notes for virtual machines

If the external computer is a VM, use:

- Bridged networking
- the correct physical network interface

Do not use NAT/shared networking if ROS 2 topic discovery does not work reliably.

## Multicast test

If the topics are not visible, test DDS multicast.

On one machine:
```bash
ros2 multicast receive
```
On the other:
```bash
ros2 multicast send
```
If multicast does not work, ROS 2 discovery may fail even if basic IP connectivity works.

# 7. Visualize the generated map in RViz2

On the external computer:
```bash
source /opt/ros/humble/setup.bash
export ROS_DOMAIN_ID=0
export ROS_LOCALHOST_ONLY=0
export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp
rviz2
```
Inside RViz2, add the following displays as needed:

Map
LaserScan
TF
RobotModel

Typical topics:

Map topic:
/map
Laser topic:
/scan
TF:
/tf
/tf_static

Set the fixed frame according to the robot setup, typically something like:

map
odom
or base_link

If RViz2 does not open and shows a display/X11-related error, make sure you are running it in a valid graphical desktop session.
