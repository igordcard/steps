#!/bin/bash

kubectl describe ns ns1

kubectl delete ns ns1
kubectl delete csr lc1-user-csr
