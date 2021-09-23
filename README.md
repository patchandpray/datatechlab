# Data Tech Lab

This data tech lab is intended as a learning and improvement environment for playing around and coming to grasps with cutting-edge cloud-native (data) technologies and methodologies.

## K3S
K3S is an extremely lightweight and portable kubernetes version developed by Rancher.
It contains all the kubernetes api's in one binary with tools for managing and running resources on kubernetes included.
It is perfect for edge and iot but also for local development!

## K3D
To simulate multiple nodes we use K3D which is a wrapper around K3S to enable it to run in Docker. This way we can simulate a multi nodes cluster locally.
https://k3d.io/v4.4.8/ for quickstart instructions.

A prerequisite of K3D is docker so make sure docker is installed and running. The makefile atleast checks if it is running but installing you will have to take care of yourself.

K3D is installed as part of `make setup`

## HELM
Helm is a package manager for kubernetes. It is used for installing and managing simple but usually complex multi component infrastructure on kubernetes in a maintainable way.
Nowadays most infra that is to be run on Kubernetes comes with HELM charts for installing and managing them. These charts are usually pretty complex thought but are a very good
source of domain specific info for the infra you are installing. Usually containing some best practices and configuration gems that aren't always clear from documentation itself.

HELM is installed as part of `make setup`

## K8Ssandra
