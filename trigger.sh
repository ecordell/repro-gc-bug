#! /bin/bash

. ./lib.sh

kubectl config use-context minikube

while true; do
    date
   # kubectl -n kube-system exec kube-controller-manager-minikube -c kube-controller-manager reboot
   # sel=$(kubectl get deployment mock-apiserver --output=json | jq -j '.spec.selector.matchLabels | to_entries | .[] | "\(.key)=\(.value)"')
   # kubectl delete pods --selector=$sel

    genCRDs 20
    genAPIs 20

    kubectl -n kube-system exec kube-apiserver-minikube -c kube-apiserver reboot

    retries=60
    until [[ $retries == 0 || "$(minikube status --format '{{.ApiServer}}')" = "Running" ]]; do
        sleep 5
        retries=$((retries - 1))
        echo "waiting for apiserver to return"
    done

    if [ $retries == 0 ]
    then
        echo "apiserver never returned"
        exit 1
    fi

    kubectl get configmap 
done

