#!/bin/bash
trap : SIGTERM SIGINT

function absPath() 
{
    # generate absolute path from relative path
    # $1     : relative filename
    # return : absolute path
    if [ -d "$1" ]; then
        # dir
        (cd "$1"; pwd)
    elif [ -f "$1" ]; then
        # file
        if [[ $1 = /* ]]; then
            echo "$1"
        elif [[ $1 == */* ]]; then
            echo "$(cd "${1%/*}"; pwd)/${1##*/}"
        else
            echo "$(pwd)/$1"
        fi
    fi
}

function relativePath()
{
    # both $1 and $2 are absolute paths beginning with /
    # returns relative path to $2/$target from $1/$source
    source=$1
    target=$2

    common_part=$source # for now
    result="" # for now

    while [[ "${target#$common_part}" == "${target}" ]]; do
        # no match, means that candidate common part is not correct
        # go up one level (reduce common part)
        common_part="$(dirname $common_part)"
        # and record that we went back, with correct / handling
        if [[ -z $result ]]; then
            result=".."
        else
            result="../$result"
        fi
    done

    if [[ $common_part == "/" ]]; then
        # special case for root (no common path)
        result="$result/"
    fi

    # since we now have identified the common part,
    # compute the non-common part
    forward_part="${target#$common_part}"

    # and now stick all parts together
    if [[ -n $result ]] && [[ -n $forward_part ]]; then
        result="$result$forward_part"
    elif [[ -n $forward_part ]]; then
        # extra slash removal
        result="${forward_part:1}"
    fi

    echo $result
}

# Assuming the last argument is the path to the config file
CONFIG_DIR_PATH="$HOME/bag_files/current_config_files/"
#CONFIG_FILE_NAME="vins_config.yaml"

# Update CONFIG_IN_DOCKER to new path inside the container
CONFIG_IN_DOCKER="/config_files/vins_config.yaml"

# Where the Vins directory is located in the repository
VINS_FUSION_DIR=$"$HOME/new_nano_ws/src/mapping/VINS-Fusion-Noetic/"

echo $CONFIG_FILE_PATH
echo $CONFIG_DIR_PATH
echo $CONFIG_FILE_NAME
echo $CONFIG_IN_DOCKER
echo $VINS_FUSION_DIR

VINS_FUSION_DIR=$(absPath "..")

docker run \
-it \
--rm \
--net=host \
-v ${VINS_FUSION_DIR}:/root/catkin_ws/src/VINS-Fusion/ \
-v ${CONFIG_DIR_PATH}:/config_files \
ros:vins-fusion \
/bin/bash -c \
"cd /root/catkin_ws/; \
catkin config \
--env-cache \
--extend /opt/ros/$ROS_DISTRO \
--cmake-args \
    -DCMAKE_BUILD_TYPE=Release; \
catkin build; \
source devel/setup.bash; \
roslaunch vins cs3.launch"

