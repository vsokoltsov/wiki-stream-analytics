# Kubernetes Charts

This directory contains the Helm charts used to deploy Kubernetes-side infrastructure and workloads for Wiki Stream Analytics.

The charts here are separate from Terraform:

- Terraform creates the GKE cluster, namespaces, base add-ons, cloud identities, and cloud resources
- Helm charts deploy workload-level Kubernetes objects into that cluster

In practice:

- `infra/terraform` provisions the platform
- `infra/k8s` deploys applications and cluster-facing runtime config

## Directory Layout

Charts live under [charts](/Users/vadim.sokoltsov/learning/wiki-stream-analytics/infra/k8s/charts):

- [common](/Users/vadim.sokoltsov/learning/wiki-stream-analytics/infra/k8s/charts/common)
- [edge-access](/Users/vadim.sokoltsov/learning/wiki-stream-analytics/infra/k8s/charts/edge-access)
- [wiki-producer](/Users/vadim.sokoltsov/learning/wiki-stream-analytics/infra/k8s/charts/wiki-producer)
- [wiki-processing](/Users/vadim.sokoltsov/learning/wiki-stream-analytics/infra/k8s/charts/wiki-processing)

## Chart Overview

### `common`

Path:
[common](/Users/vadim.sokoltsov/learning/wiki-stream-analytics/infra/k8s/charts/common)

Purpose:

- shared Helm helper templates
- reusable naming/labeling logic for other charts

Important detail:

- this is a Helm library chart (`type: library`)
- it is not installable on its own
- other charts can import helpers from it

### `edge-access`

Path:
[edge-access](/Users/vadim.sokoltsov/learning/wiki-stream-analytics/infra/k8s/charts/edge-access)

Purpose:

- create public-facing Kubernetes `Service` objects for selected workloads
- expose internal workloads such as Flink UI through a cloud load balancer

Default example:

- exposes `flink-ui` in namespace `wikistream`
- forwards port `8081`

Typical use case:

- publish a workload UI or HTTP endpoint without modifying the workload chart itself

### `wiki-producer`

Path:
[wiki-producer](/Users/vadim.sokoltsov/learning/wiki-stream-analytics/infra/k8s/charts/wiki-producer)

Purpose:

- deploy the producer application that consumes Wikimedia recent-change events
- publish those events into Kafka

Typical contents:

- `Deployment`
- `ServiceAccount`
- config map
- SecretProviderClass / secret sync objects

Important runtime assumptions:

- Kafka bootstrap and secret values are provisioned separately
- Workload Identity may be pre-created by Terraform
- the image is expected in Artifact Registry

### `wiki-processing`

Path:
[wiki-processing](/Users/vadim.sokoltsov/learning/wiki-stream-analytics/infra/k8s/charts/wiki-processing)

Purpose:

- deploy the stream-processing workload on Flink
- configure the Flink job, runtime environment, and optional ingress

Typical contents:

- Flink deployment-related resources
- service account wiring
- RBAC
- ingress
- secret provider / secret sync objects

Important runtime assumptions:

- Flink Operator is already installed by Terraform
- target namespace already exists
- service accounts may be managed outside the chart

## Prerequisites

Before working with these charts, you need:

- a working GKE cluster
- `kubectl`
- `helm` 3.x
- access to the target namespace
- GKE credentials in the current kubeconfig

Example:

```bash
gcloud container clusters get-credentials <GKE_CLUSTER> \
  --region <GCP_REGION> \
  --project <GCP_PROJECT_ID>
```

Check cluster access:

```bash
kubectl get ns
kubectl config current-context
```

## Validation Workflow

There is a dedicated GitHub Actions workflow for this directory:

- [k8s.yml](/Users/vadim.sokoltsov/learning/wiki-stream-analytics/.github/workflows/k8s.yml)

It runs when:

- something under `infra/k8s/**` changes
- or the workflow file itself changes

What it validates:

- Helm dependencies
- `helm lint`
- `helm template`

Library charts such as `common` are skipped for install/render validation because Helm does not render them directly.

## Local Validation

### Build dependencies

```bash
helm dependency build infra/k8s/charts/wiki-producer
helm dependency build infra/k8s/charts/wiki-processing
helm dependency build infra/k8s/charts/edge-access
```

### Lint charts

```bash
helm lint infra/k8s/charts/wiki-producer
helm lint infra/k8s/charts/wiki-processing
helm lint infra/k8s/charts/edge-access
```

### Render manifests

```bash
helm template wiki-producer infra/k8s/charts/wiki-producer \
  -f infra/k8s/charts/wiki-producer/values.yaml

helm template wiki-processing infra/k8s/charts/wiki-processing \
  -f infra/k8s/charts/wiki-processing/values.yaml

helm template edge-access infra/k8s/charts/edge-access \
  -f infra/k8s/charts/edge-access/values.yaml
```

## Deployment Guide

### `wiki-producer`

Build dependencies first:

```bash
helm dependency build infra/k8s/charts/wiki-producer
```

Install or upgrade:

```bash
helm upgrade --install wiki-producer infra/k8s/charts/wiki-producer \
  --namespace wikistream \
  --create-namespace \
  --set image.repository="europe-west3-docker.pkg.dev/<GCP_PROJECT_ID>/wiki-stream-analytics/wiki-producer" \
  --set image.tag="<IMAGE_TAG>" \
  --set gcp.projectId="<GCP_PROJECT_ID>"
```

If Terraform already created the Kubernetes service account, set:

```bash
--set serviceAccount.create=false \
--set serviceAccount.name=producer-sa
```

### `wiki-processing`

Build dependencies if needed:

```bash
helm dependency build infra/k8s/charts/wiki-processing
```

Install or upgrade:

```bash
helm upgrade --install wiki-processing infra/k8s/charts/wiki-processing \
  --namespace wikistream \
  --set image.repository="europe-west3-docker.pkg.dev/<GCP_PROJECT_ID>/wiki-stream-analytics/wiki-processing" \
  --set image.tag="<IMAGE_TAG>" \
  --set gcp.projectId="<GCP_PROJECT_ID>"
```

If the service account is managed outside the chart:

```bash
--set serviceAccount.create=false \
--set serviceAccount.name=processing-sa
```

### `edge-access`

Install or upgrade:

```bash
helm upgrade --install edge-access infra/k8s/charts/edge-access \
  --namespace wikistream \
  -f infra/k8s/charts/edge-access/values.yaml
```

To pin a static public IP:

```bash
helm upgrade --install edge-access infra/k8s/charts/edge-access \
  --namespace wikistream \
  --set services[0].loadBalancerIP="<STATIC_IP>"
```

## Values and Configuration

Each application chart has a `values.yaml` file with the default configuration:

- [wiki-producer values](/Users/vadim.sokoltsov/learning/wiki-stream-analytics/infra/k8s/charts/wiki-producer/values.yaml)
- [wiki-processing values](/Users/vadim.sokoltsov/learning/wiki-stream-analytics/infra/k8s/charts/wiki-processing/values.yaml)
- [edge-access values](/Users/vadim.sokoltsov/learning/wiki-stream-analytics/infra/k8s/charts/edge-access/values.yaml)

The most important values to review before deployment are:

- image repository and tag
- GCP project ID
- service account creation mode
- namespace
- ingress / public access settings
- environment variables

For production use, prefer an environment-specific values file instead of editing the default `values.yaml` directly.

Example:

```bash
helm upgrade --install wiki-producer infra/k8s/charts/wiki-producer \
  --namespace wikistream \
  -f infra/k8s/charts/wiki-producer/values.yaml \
  -f infra/k8s/charts/wiki-producer/values.prod.yaml
```

## Operational Notes

- `common` is a helper chart only and should not be installed directly
- `wiki-processing` depends on Flink Operator being installed first
- service accounts may be created either by Helm or externally by Terraform; keep that ownership clear
- secret-provider and secret-sync resources assume the cluster has the required CSI / secret sync components installed
- `edge-access` is a good place to manage public exposure separately from application deployment

## Useful Commands

Show rendered resources for a single template:

```bash
helm template wiki-producer infra/k8s/charts/wiki-producer \
  -f infra/k8s/charts/wiki-producer/values.yaml \
  --show-only templates/deployment.yaml
```

Inspect a Helm release:

```bash
helm list -n wikistream
helm status wiki-producer -n wikistream
```

Check rollout status:

```bash
kubectl -n wikistream get pods
kubectl -n wikistream rollout status deployment/wiki-producer-wiki-producer
```
