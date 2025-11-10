#!/bin/bash
set -e

sudo apt install psmisc -y

docker container prune

echo "Starting Streamlit deployment..."

echo "Stopping existing Streamlit app..."
sudo fuser -k 8501/tcp || true


echo "Searching for containers on port 8501..."

# Find all containers (running or stopped) on port 8501
CONTAINERS=$(sudo docker ps -aq --filter "publish=8501")

if [ -z "$CONTAINERS" ]; then
    echo " No containers found on port 8501"
    exit 0
fi

# Process each container
for CONTAINER_ID in $CONTAINERS; do
    # Get image name
    IMAGE_NAME=$(sudo docker inspect --format='{{.Config.Image}}' $CONTAINER_ID 2>/dev/null)
    CONTAINER_NAME=$(sudo docker inspect --format='{{.Name}}' $CONTAINER_ID 2>/dev/null | sed 's/\///')
    
    echo ""
    echo "Container: $CONTAINER_NAME ($CONTAINER_ID)"
    echo " Image: $IMAGE_NAME"
    
    # Remove container
    echo " Removing container..."
    sudo docker rm -f $CONTAINER_ID
    
    # Remove image
    echo " Removing image..."
    sudo docker rmi $IMAGE_NAME 2>/dev/null || echo " Image might be used by other containers"
    
    echo "Cleaned up!"
done

echo ""
echo " All done!"

# Show remaining images
echo ""
echo "Remaining rag-chatbot images:"
sudo docker images | grep rag-chatbot || echo "None"

# pull Docker image