#!/bin/bash 

# Ensure EKS context is set
aws eks update-kubeconfig --name taxi-eks-cluster --region us-east-1

# Create namespace first
kubectl apply -f k8s/namespace.yaml

# Update deployment with the new image
sed -i "s|image:.*|image: $ECR_REPO:$IMAGE_TAG|g" k8s/deployment.yaml

# Apply k8s manifests
kubectl apply -f k8s/deployment.yaml 
kubectl apply -f k8s/service.yaml 
