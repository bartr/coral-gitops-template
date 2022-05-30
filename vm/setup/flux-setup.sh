#!/bin/bash

echo "$(date +'%Y-%m-%d %H:%M:%S')  flux bootstrap start" >> "$HOME/status"

if [ ! "$(flux --version)" ]
then
  echo "$(date +'%Y-%m-%d %H:%M:%S')  flux not found" >> "$HOME/status"
  echo "$(date +'%Y-%m-%d %H:%M:%S')  flux bootstrap failed" >> "$HOME/status"
  exit 1
fi

if [ -z "$AKDC_BRANCH" ]
then
  echo "$(date +'%Y-%m-%d %H:%M:%S')  AKDC_BRANCH not set" >> "$HOME/status"
  echo "$(date +'%Y-%m-%d %H:%M:%S')  flux bootstrap failed" >> "$HOME/status"
  echo "AKDC_BRANCH not set"
  exit 1
fi

if [ -z "$AKDC_CLUSTER" ]
then
  echo "$(date +'%Y-%m-%d %H:%M:%S')  AKDC_CLUSTER not set" >> "$HOME/status"
  echo "$(date +'%Y-%m-%d %H:%M:%S')  flux bootstrap failed" >> "$HOME/status"
  echo "AKDC_CLUSTER not set"
  exit 1
fi

if [ ! -f /home/akdc/.ssh/akdc.pat ]
then
  echo "$(date +'%Y-%m-%d %H:%M:%S')  akdc.pat not found" >> "$HOME/status"
  echo "$(date +'%Y-%m-%d %H:%M:%S')  flux bootstrap failed" >> "$HOME/status"
  echo "akdc.pat not found"
  exit 1
fi

git pull
kubectl apply -f "$HOME/gitops/deploy/flux/$AKDC_CLUSTER/flux-system/dev/flux-system/namespace.yaml"
flux create secret git flux-system -n flux-system --url https://github.com/retaildevcrews/bartr-fleet -u gitops -p "$AKDC_PAT"
kubectl apply -f "$HOME/gitops/deploy/flux/$AKDC_CLUSTER/flux-system/dev/flux-system/controllers.yaml"
sleep 3
kubectl apply -f "$HOME/gitops/deploy/flux/$AKDC_CLUSTER/flux-system/dev/flux-system/source.yaml"
sleep 2
kubectl apply -f "$HOME/gitops/deploy/flux/$AKDC_CLUSTER/flux-system/dev/flux-system/*.yaml"
sleep 5

flux reconcile source git gitops

kubectl get pods -A

flux get kustomizations

echo "$(date +'%Y-%m-%d %H:%M:%S')  flux bootstrap complete" >> "$HOME/status"
