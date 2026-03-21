# FastBot ROS 2 — Docker Compose Deployment

This project can be started directly from Docker Hub using `docker compose` / `docker-compose`, without rebuilding the images locally.

## Prerequisites on the host

Before running the stack, make sure the host machine has:

- Docker installed
- Docker Compose installed
- X11 enabled for GUI applications
- Access to the project repository
- A running graphical session so Gazebo can open on the host display

---

## 1. Install Docker and Docker Compose

The following commands were used on the host:

```bash
sudo apt-get update
sudo apt-get install -y docker.io docker-compose
sudo service docker start
Notes
This installs the Ubuntu package versions of:
docker.io
docker-compose
The exact version number is not recorded here, only the installation method is known.

You can check the installed versions with:

docker --version
docker-compose --version
2. Allow running Docker without sudo

To avoid typing sudo docker ... and sudo docker-compose ..., add your user to the docker group:

sudo usermod -aG docker $USER
newgrp docker
Verify it works
docker ps
docker-compose version

If this does not work immediately, log out and log back in.

3. Clone the repository

First, clone the repository to the host machine:

git clone <REPOSITORY_URL>
cd <REPOSITORY_FOLDER>

Then go to the Docker Compose directory:

cd ros2_ws/src/fastbot_ros2_docker/simulation

Replace <REPOSITORY_URL> and <REPOSITORY_FOLDER> with the actual repository URL and folder name.

4. Enable X11 forwarding for Gazebo

Gazebo needs access to the host X server to display its GUI window.

Allow local Docker containers to access X11
xhost +local:docker

In some environments, the following may also work:

xhost +local:
Check DISPLAY
echo $DISPLAY

A typical value is:

:0

If DISPLAY is empty, Gazebo will not open on the screen.

5. Pull images from Docker Hub

Since the images are already published on Docker Hub, you do not need to build them locally.

Because your docker-compose.yml contains both:

build: ...
image: ...

Docker Compose may still try to build, depending on the command used and the local state.

To force pulling the published images first, run:

docker-compose pull

Then start the stack:

docker-compose up
Recommended startup
cd ros2_ws/src/fastbot_ros2_docker/simulation
docker-compose pull
docker-compose up
Run in background
docker-compose up -d
6. Docker Compose behavior: pull vs build

Because the compose file contains both build and image, the safest workflow for using Docker Hub images is:

docker-compose pull
docker-compose up

If you want to make sure Compose does not rebuild anything, avoid using --build.

If needed, you can also explicitly prevent rebuild-style workflows by using the already pulled images only.

7. Network

The compose file defines its own bridge network:

networks:
  fastbot-net:
    driver: bridge

Docker Compose will create this network automatically when you run:

docker-compose up

So in the Compose-based workflow, you do not need to manually run:

docker network create fastbot-net

That manual step is only needed when starting standalone containers with plain docker run.

8. Start the full stack

From:

cd ros2_ws/src/fastbot_ros2_docker/simulation

Run:

docker-compose pull
docker-compose up

This starts:

fastbot-ros2-gazebo
fastbot-ros2-slam
fastbot-ros2-webapp
Exposed ports

The webapp service exposes:

7000:80
9090:9090

So the web interface should be reachable at:

http://localhost:7000
9. Useful container commands
List running containers
docker ps
Open a shell inside the Gazebo container
docker exec -it fastbot-ros2-gazebo bash
Open a shell inside the SLAM container
docker exec -it fastbot-ros2-slam bash
Open a shell inside the WebApp container
docker exec -it fastbot-ros2-webapp bash
10. Send /cmd_vel manually

You can publish a velocity command from inside a ROS 2 container.

For example, enter the Gazebo container:

docker exec -it fastbot-ros2-gazebo bash

Then publish one movement command:

ros2 topic pub --once /fastbot/cmd_vel geometry_msgs/msg/Twist \
"{linear: {x: 0.2, y: 0.0, z: 0.0}, angular: {x: 0.0, y: 0.0, z: 0.0}}"

Example rotation command:

ros2 topic pub --once /fastbot/cmd_vel geometry_msgs/msg/Twist \
"{linear: {x: 0.0, y: 0.0, z: 0.0}, angular: {x: 0.0, y: 0.0, z: 0.5}}"
11. Control the robot from keyboard

Enter the Gazebo container:

docker exec -it fastbot-ros2-gazebo bash

Run teleoperation:

ros2 run teleop_twist_keyboard teleop_twist_keyboard --ros-args --remap cmd_vel:=/fastbot/cmd_vel

This lets you drive the robot using the keyboard.

12. Useful debugging commands
View logs for all services
docker-compose logs
Follow logs live
docker-compose logs -f
View logs for one service
docker-compose logs -f fastbot-ros2-gazebo
docker-compose logs -f fastbot-ros2-slam
docker-compose logs -f fastbot-ros2-webapp
Check ROS 2 topics inside a container
docker exec -it fastbot-ros2-gazebo bash
ros2 topic list
Check if /cmd_vel exists
ros2 topic list | grep cmd_vel
Check topic messages
ros2 topic echo /fastbot/odom
13. Stop the stack

To stop all services:

docker-compose down

To stop and remove volumes as well:

docker-compose down -v
14. Restart the stack
docker-compose down
docker-compose up

Or in detached mode:

docker-compose down
docker-compose up -d
15. Host-side checklist

Before starting the project, make sure the host has completed the following:

Docker is installed
Docker Compose is installed
Docker service is running
The user can run Docker without sudo
The repository has been cloned
The shell is inside ros2_ws/src/fastbot_ros2_docker/simulation

X11 access is enabled with:

xhost +local:docker

DISPLAY is set:

echo $DISPLAY

Docker Hub images have been pulled:

docker-compose pull
The stack is started:
docker-compose up
16. Recommended quick start
sudo apt-get update
sudo apt-get install -y docker.io docker-compose
sudo service docker start

sudo usermod -aG docker $USER
newgrp docker

git clone <REPOSITORY_URL>
cd <REPOSITORY_FOLDER>/ros2_ws/src/fastbot_ros2_docker/simulation

xhost +local:docker

docker --version
docker-compose --version

docker-compose pull
docker-compose up
17. Notes
fastbot-ros2-gazebo needs X11 access to display Gazebo on the host.
fastbot-ros2-webapp exposes the frontend on port 7000.
fastbot-ros2-slam depends on the Gazebo service.
Compose automatically creates the fastbot-net network.

If you want to use the Docker Hub images, prefer:

docker-compose pull
docker-compose up

instead of rebuilding locally.


A couple of practical notes for your case:

1. **Yes, pull does not happen “magically” in the way you want to rely on.**  
   With this compose file, the safest command is:

```bash
docker-compose pull
docker-compose up
Since your compose file still contains build:, if you want a pure Docker Hub deployment, the cleanest long-term solution is to remove the build: sections and keep only image:.

Then startup becomes simply:

docker-compose up

and Compose will use the remote images.

For Gazebo GUI on Linux host, xhost +local:docker is usually the key host-side step.