#!/bin/bash

FLINK_UI_IP="$(terraform -chdir=infra/terraform output -raw flink_public_ip)"

helm upgrade --install edge-access infra/k8s/charts/edge-access \
  -n wikistream --create-namespace \
  -f infra/k8s/charts/edge-access/values.yaml \
  --set "services[0].loadBalancerIP=${FLINK_UI_IP}"