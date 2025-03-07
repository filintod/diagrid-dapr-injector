# Diagrid Dapr Injector Helm Library Chart

## Overview

The Diagrid Dapr Injector is a Helm library chart designed to inject the Dapr sidecar into your Kubernetes application workloads (e.g., Deployments, StatefulSets). This chart is based on the [dapr/dapr](https://github.com/dapr/dapr) project but functions as a library chart rather than a standalone installation.

## Prerequisites

- Kubernetes cluster
- Helm 3.x

## Installation

This chart is not intended for standalone use. Instead, incorporate it as a dependency in your existing Helm charts.

### Step 0: Set-up the Dapr control plane on the cluster

Use Helm to install the Dapr control plane in your cluster. For example to install the OSS Dapr version, see example below. Additional instructions found in [docs](https://docs.dapr.io/operations/hosting/kubernetes/kubernetes-deploy/).

This can be installed without the Dapr sidecar injector control plane service since that will be added via the Helm Library Chart.

``` bash
helm install dapr dapr/dapr --version=1.14.4 --namespace dapr-system --create-namespace --set global.ha.enabled=false --set dapr_operator.watch_interval=3m --set dapr_sidecar_injector.enabled=false --wait
```

### Step 1: Add the Dependency

In your Helm chart's `Chart.yaml` file, add the following dependency:

```yaml
dependencies:
  - name: diagrid-dapr-injector
    version: 0.1.0
    repository: file://../diagrid-dapr-injector  # this is the path to the local chart on your filesystem or a remote chart repository
```

Update your Helm chart dependencies:

```bash
helm dependency update
```

### Step 2: Configure Values

In your `values.yaml` file, add any necessary overrides for the injector:

```yaml
dapr:  
  image: 
    tag: "1.14.4"
  ha:
    enabled: true
  controlPlaneNamespace: dapr-system
  controlPlaneTrustDomain: cluster.local

podAnnotations:
  dapr.io/enabled: "true"
  dapr.io/app-id: "myapp"
  dapr.io/app-port: "5000"
```

#### Configuration Values

The default values are defined in the [templates/_helpers.tpl](diagrid-dapr-injector/templates/_helpers.tpl) file. Key configuration options include:

- `dapr.image`: Dapr sidecar image settings
- `dapr.controlPlaneNamespace`: Namespace for the Dapr control plane
- `dapr.controlPlaneTrustDomain`: Trust domain for the cluster
- `dapr.actors`: Actor service configuration
- `dapr.reminders`: Reminder service configuration
- `dapr.scheduler`: Scheduler settings
- `dapr.ha`: High availability settings
- `dapr.mtls`: mTLS configuration
- `dapr.prometheus`: Prometheus metrics settings

For a complete list of configuration options, refer to the `templates/_helpers.tpl` file in the chart.

### Step 3: Update Workload Templates

Modify your workload templates (e.g., `templates/deployment.yaml`) to include the Dapr sidecar:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Release.Name }}-deployment
  labels:
    app: {{ .Release.Name }}
spec:
  replicas: 1
  selector:
    matchLabels:
      app: {{ .Release.Name }}
  template:
    metadata:
      labels:
        app: {{ .Release.Name }}
      annotations:
        {{ toYaml .Values.podAnnotations | nindent 8 | trim}}
    spec:
      containers:
      - name: {{ .Chart.Name }}
        image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
        imagePullPolicy: {{ .Values.image.pullPolicy }}
      {{ include "diagrid-dapr-injector.sidecar" (dict "podAnnotations" .Values.podAnnotations "helmCtx" .) | nindent 6 }}
      volumes:
        {{ include "diagrid-dapr-injector.volumes" . | nindent 8 }}  
```

### Step 4 (Optional): Add Trust Anchors

Trust anchors are essential for verifying the authenticity of the Dapr control plane.

By default, this sidecar injector library does not require explicit trust anchor configuration when the Dapr control plane and the workload are in the same namespace. In this scenario, the sidecar injector automatically utilizes the default trust anchors for the control plane via the Kubernetes downward API.

However, manual configuration of trust anchors is necessary when the Dapr control plane operates in a different namespace than the workload.

In this situation, you must manually supply the trust anchors to the sidecar injector through the `dapr.trustAnchors` field in your values file or Helm command.

To retrieve the trust anchors from the Dapr control plane namespace within a Kubernetes cluster, run the following command:

```bash
kubectl get secret -n dapr-system dapr-trust-bundle -o jsonpath="{.data['ca\.crt']}" | base64 -d | tee /tmp/trust-anchors.crt
```

#### Passing the Trust Anchors to the Dapr Sidecar Injector

If the workload is in a different namespace than the Dapr control plane, you can pass the trust anchors to the Dapr sidecar injector by setting the `dapr.trustAnchors` field in the `values.yaml` file:

```yaml
dapr:
  trustAnchors: |
    -----BEGIN CERTIFICATE-----
    MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA5+1q1Qy9X/PvO8Vc0P9M
    ...
    -----END CERTIFICATE-----
```

Alternatively, you can pass the trust anchors via the Helm install/upgrade `set` command. For example, if you saved the trust anchors to a file `/tmp/trust-anchors.crt`, you can pass it to the Dapr sidecar injector as follows:

```bash
# also showing passing the image tag, custom control plane namespace, and the trust anchors from a file
helm template --set dapr.controlPlaneNamespace=dapr-system-3 --set "dapr.image.tag=1.14.4" --set-file dapr.trustAnchors=/tmp/trust-anchors.crt -n dapr-system-3 deploy-sample 
```

### Step 5: Template Helm values and deploy Helm chart

Check the results of your Helm chart by running the following command.

```bash
helm template <your-Helm-chart> <path-to-your-helm-chart> -f values.yaml 
```

Deploy your Helm chart with the diagrid-dapr-injector dependency after verifying the manifests are generated correctly.

```bash
helm install -f values.yaml <your-Helm-chart> <path-to-your-helm-chart>
```

For example to test the sample Helm chart that is deployed in this repo, ensure the [values](deploy-sample/values.yaml) are updated correctly and then run the following:

```bash
cd deploy-sample
helm template example-chart . -f values.yaml 
helm install  example-chart . -f values.yaml
```

## Support

For issues, feature requests, or questions, please file an issue in the [GitHub repository](https://github.com/diagridio/diagrid-dapr-injector).

## License

[TBD]