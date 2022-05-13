#!/bin/bash

# debug & troubleshoot

kubectl run -it --rm --restart=Never busybox --image=gcr.io/google-containers/busybox sh
