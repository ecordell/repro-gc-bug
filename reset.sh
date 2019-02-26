#! /bin/bash

minikube delete
minikube start --kubernetes-version="v1.12.0" --extra-config=apiserver.v=5 --extra-config=controller-manager.v=5