#!/bin/bash

echo "$(date +'%Y-%m-%d %H:%M:%S')  flux bootstrap start" >> "$HOME/status"

# make sure flux is installed
if [ ! "$(flux --version)" ]
then
  echo "$(date +'%Y-%m-%d %H:%M:%S')  flux not found" >> "$HOME/status"
  echo "$(date +'%Y-%m-%d %H:%M:%S')  flux bootstrap failed" >> "$HOME/status"
  exit 1
fi

# make sure the branch is set
if [ -z "$AKDC_BRANCH" ]
then
  echo "$(date +'%Y-%m-%d %H:%M:%S')  AKDC_BRANCH not set" >> "$HOME/status"
  echo "$(date +'%Y-%m-%d %H:%M:%S')  flux bootstrap failed" >> "$HOME/status"
  echo "AKDC_BRANCH not set"
  exit 1
fi

# make sure cluster name is set
if [ -z "$AKDC_CLUSTER" ]
then
  echo "$(date +'%Y-%m-%d %H:%M:%S')  AKDC_CLUSTER not set" >> "$HOME/status"
  echo "$(date +'%Y-%m-%d %H:%M:%S')  flux bootstrap failed" >> "$HOME/status"
  echo "AKDC_CLUSTER not set"
  exit 1
fi

# make sure PAT is set
if [ ! -f /home/akdc/.ssh/akdc.pat ]
then
  echo "$(date +'%Y-%m-%d %H:%M:%S')  akdc.pat not found" >> "$HOME/status"
  echo "$(date +'%Y-%m-%d %H:%M:%S')  flux bootstrap failed" >> "$HOME/status"
  echo "akdc.pat not found"
  exit 1
fi

git pull

# status_code=1
# retry_count=0

# # retry loop
# until [ $status_code == 0 ]
# do

#   echo "flux retries: $retry_count"
#   echo "$(date +'%Y-%m-%d %H:%M:%S')  flux retries: $retry_count" >> "$HOME/status"

#   if [ $retry_count -gt 0 ]
#   then
#     sleep $((RANDOM % 30+15))
#   fi

#   retry_count=$((retry_count + 1))

#   # fail after 10 retries
#   if [ $retry_count -gt 10 ]
#   then
#     exit 1
#   fi

#   # run flux bootstrap
#   flux bootstrap git \
#   --url "https://github.com/$AKDC_REPO" \
#   --branch "$AKDC_BRANCH" \
#   --password "$(cat /home/akdc/.ssh/akdc.pat)" \
#   --token-auth true \
#   --path "./clusters/$AKDC_CLUSTER"

#   status_code=$?
# done

# echo "adding flux sources"
# echo "$(date +'%Y-%m-%d %H:%M:%S')  adding flux sources" >> "$HOME/status"

# # add flux secret
# flux create secret git gitops \
#   -n flux-system \
#   --url https://github.com/bartr/coral-fleet \
#   -u gitops \
#   -p "$AKDC_PAT"

# # add flux source
# flux create source git gitops \
# --namespace flux-system \
# --url "https://github.com/$AKDC_REPO" \
# --branch "$AKDC_BRANCH" \
# --secret-ref gitops

# # add flux kustomizations
# flux create kustomization bootstrap \
# --namespace flux-system \
# --source GitRepository/gitops \
# --path "./deploy/bootstrap/$AKDC_CLUSTER" \
# --prune true \
# --interval 1m

# flux create kustomization apps \
# --namespace flux-system \
# --source GitRepository/gitops \
# --path "./deploy/apps/$AKDC_CLUSTER" \
# --prune true \
# --interval 1m

flux create secret git flux-system -n flux-system --url https://github.com/microsoft/coral-gitops -u gitops -p "$AKDC_PAT"
flux create secret git gitops -n flux-system --url https://github.com/microsoft/coral-gitops -u gitops -p "$AKDC_PAT"

kubectl apply -f "$HOME/gitops/deploy/flux/$AKDC_CLUSTER/flux-system/dev/flux-system/controllers.yaml"
sleep 3
kubectl apply -f "$HOME/gitops/deploy/flux/$AKDC_CLUSTER/flux-system/dev/flux-system/source.yaml"
sleep 2
kubectl apply -f "$HOME/gitops/deploy/flux/$AKDC_CLUSTER/flux-system/dev/flux-system/*.yaml"
sleep 5

# force flux to sync
flux reconcile source git gitops

# display results
kubectl get pods -A
flux get kustomizations

echo "$(date +'%Y-%m-%d %H:%M:%S')  flux bootstrap complete" >> "$HOME/status"
