#!/bin/bash

# Set variables (adjust as needed)
IMAGE_NAME="symfony-app"
IMAGE_TAG="latest"
DOCKER_REGISTRY="your-registry-url" 

# Create dev namespace if it doesn't exist
kubectl create namespace dev --dry-run=client -o yaml | kubectl apply -f - 

# Build the Docker image
#docker build -t $IMAGE_NAME:$IMAGE_TAG .

# If using a registry, push the image
if [[ -n $DOCKER_REGISTRY ]]; then
    docker tag $IMAGE_NAME:$IMAGE_TAG $DOCKER_REGISTRY/$IMAGE_NAME:$IMAGE_TAG 
    docker push $DOCKER_REGISTRY/$IMAGE_NAME:$IMAGE_TAG
fi

# Create ConfigMaps (only if they don't exist)
kubectl create configmap apache-config --from-file=apache.conf --dry-run=client -o yaml -n dev | kubectl apply -f - -n dev
kubectl create configmap entrypoint-config --from-file=entrypoint.sh --dry-run=client -o yaml -n dev | kubectl apply -f - -n dev

# Apply Kubernetes manifests
kubectl apply -f deployment.yaml -n dev
kubectl apply -f service.yaml -n dev
kubectl apply -f ingress.yaml -n dev
