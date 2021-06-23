#!/bin/bash
# Export Docker image as Singularity .sif file
# Maintainer: Matthew N. Giarra <matthew.giarra@gmail.com>
# First commit 2021-06-10

# Colors for printing
DIR='\033[95m'
OKBLUE='\033[94m'
OKCYAN='\033[96m'
OKGREEN='\033[92m'
ENDC='\033[0m'
BOLD='\033[1m'
UNDERLINE='\033[4m'
WARNING='\033[93m'
FAIL='\033[91m'

# Color to print on success
SUCCESS=$OKCYAN

# Function to display help
display_help(){
    echo -e "$SUCCESS $(basename $0): export docker image as a singularity .sif image file"
    echo "   Usage: $(basename $0) <docker_image_name>"
    echo "   Usage: $(basename $0) <docker_image_name> <sif_path_out>"
    echo "   Example: "
    echo "      docker pull ubuntu:latest"
    echo "      ./$(basename $0) ubuntu ubuntu.sif"
    echo "   Note: run \"docker image ls\" to print available docker images"
    echo -e "$ENDC"
    exit
}

# Display help if no inputs are supplied
if [ $# -eq 0 ]; then
    display_help
fi

# Display help if -h or --h is supplied as the only input
while true; do
    case "$1" in
        -h | --help)
            display_help;;
        *)
            break;;
    esac
done

# Tag of the docker image to export as Singularity .sif file
IMAGE_NAME_IN="$1"

# Make sure the image exists so that we can print an informative message if it doesn't
MATCHING_IMAGES=$(docker images -q $IMAGE_NAME_IN)
if [ -z $MATCHING_IMAGES ]; then
    if [ -f "Dockerfile" ]; then
        while true; do
            echo -e "$WARNING Docker image$DIR $IMAGE_NAME_IN$WARNING not found, but a Dockerfile exists at $DIR$(pwd)/Dockerfile$WARNING. Do you want to build a docker image $DIR$IMAGE_NAME_IN$WARNING from this Dockerfile [y/N]? $ENDC"
            read -p "" yn
            case $yn in
                [Yy]* ) docker build --rm -t $IMAGE_NAME_IN .

                # Check that the docker image got built successfully
                MATCHING_IMAGES=$(docker images -q $IMAGE_NAME_IN)
                if [ -z $MATCHING_IMAGES ]; then
                    echo -e "$FAIL Error: failed to build docker image $DIR$IMAGE_NAME_IN$FAIL from$DIR $(pwd)/Dockerfile$FAIL. Exiting. $ENDC"
                    exit
                fi
                break
                ;;

                # Exit if the user entered "N" or anything else (i.e. chose to not build the Docker image)
                [Nn]* ) exit;;
                * ) exit;;
            esac
        done
    else
        echo -e "$FAIL Error: $DIR$IMAGE_NAME_IN$FAIL does not appear to be a locally-available docker image."
        echo -e " Available docker image tags:$DIR"
        echo -e "$(docker images | tail -n +2 | awk '{print "  ", $1}')"
        echo -e "$FAIL Hint: run \"docker images\" to print available docker images $ENDC"
        exit
    fi
fi

if [ $# -ge 2 ]; then
    # User-specified output path for .sif file
    IMAGE_PATH_OUT="$2"
else
    # Default to .sif file with same name as docker tag
    IMAGE_PATH_OUT="$IMAGE_NAME_IN.sif"
fi

# Path to the output directory
OUT_DIR=$(dirname "$IMAGE_PATH_OUT")

# Make the output directory if it doesn't exist
if [ ! -d "$OUT_DIR" ]; then
    mkdir -p "$OUT_DIR"
    if [ -d "$OUT_DIR" ]; then
        echo -e "$SUCCESS Created directory $DIR$OUT_DIR $ENDC"
    else
        echo -e "$FAIL Error: could not create directory $DIR$OUT_DIR $ENDC"
        exit 
    fi 
fi

# Absolute path to output directory
OUT_DIR_ABS=$(cd "$OUT_DIR"; pwd)

# Name of the output image
IMAGE_NAME_OUT=$(basename "$IMAGE_PATH_OUT")

# Absolute path to the output file
IMAGE_PATH_OUT_ABS="$OUT_DIR_ABS/$IMAGE_NAME_OUT"

# If the output file exists, ask if we want to overwrite it
if [ -f "$IMAGE_PATH_OUT_ABS" ]; then
    while true; do
        echo -e "$DIR$IMAGE_PATH_OUT_ABS$WARNING exists. Overwrite [y/N]? $ENDC"
        read -p "" yn
        case $yn in
            [Yy]* ) break;;
            [Nn]* ) exit;;
            * ) exit;;
        esac
    done
fi

# Backup sif file if it already exists
if [ -f "$IMAGE_PATH_OUT_ABS" ]; then
    IMAGE_PATH_ABS_BACKUP="$IMAGE_PATH_OUT_ABS.backup"
    mv "$IMAGE_PATH_OUT_ABS" "$IMAGE_PATH_ABS_BACKUP"
    
    if [ -f "$IMAGE_PATH_ABS_BACKUP" ]; then
        echo -e "$SUCCESS Backed up $DIR$IMAGE_PATH_OUT_ABS $SUCCESS-->$DIR $IMAGE_PATH_ABS_BACKUP $ENDC"
    fi
fi

# Inform the user that we're about to execute the export
echo -e "$SUCCESS Exporting docker image $DIR$IMAGE_NAME_IN $SUCCESS--> $DIR$IMAGE_PATH_OUT_ABS $ENDC"

# Export the docker image to a Singularity .sif file
docker run -v /var/run/docker.sock:/var/run/docker.sock -v "$OUT_DIR_ABS":/output -it --rm quay.io/singularity/docker2singularity --name $IMAGE_NAME_OUT $IMAGE_NAME_IN

# Check that the sif file actually got saved
if [ -f "$IMAGE_PATH_OUT_ABS" ]; then
    echo -e "$SUCCESS Exported Docker image $IMAGE_NAME_IN --> $DIR$IMAGE_PATH_OUT_ABS $ENDC"

    # Remove the backup image
    if [ -f "$IMAGE_PATH_ABS_BACKUP" ]; then
        rm "$IMAGE_PATH_ABS_BACKUP"
    fi

else
    # Replace the image with the backup image
    if [ -f "$IMAGE_PATH_ABS_BACKUP" ]; then
        echo -e "$WARNING Canceled exporting $DIR$IMAGE_NAME_IN $WARNING--> $DIR$IMAGE_PATH_OUT_ABS$ENDC"
        mv "$IMAGE_PATH_ABS_BACKUP" "$IMAGE_PATH_OUT_ABS"
    else
        echo -e "$FAIL Warning: $DIR$IMAGE_PATH_OUT_ABS$FAIL not found; exporting docker image $IMAGE_NAME_IN --> $DIR$IMAGE_PATH_OUT_ABS$FAIL appears to have failed. $ENDC"
    fi
fi