#! /bin/bash

. ./lib.sh

# starting from a fresh minikube
#minikube delete
#minikube start --kubernetes-version="v1.12.0" --extra-config=apiserver.v=5 --extra-config=controller-manager.v=5

kubectl replace --force -f crd.yaml
kubectl replace --force -f cr.yaml
uid=$(kubectl get -f cr.yaml -o=json | jq -j '.metadata.uid')
yq w -i configmap.yaml metadata.ownerReferences[0].uid $uid
kubectl replace --force -f configmap.yaml

genCRDs 3
genAPIs 1
