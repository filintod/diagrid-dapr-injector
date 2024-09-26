# Diagrid Dapr Injector Helm Library Chart

## Overview

The Diagrid Dapr Injector is a Helm library chart designed to inject the Dapr sidecar into your Kubernetes application workloads (e.g., Deployments, StatefulSets). This chart is based on the [dapr/dapr](https://github.com/dapr/dapr) project but functions as a library chart rather than a standalone installation.

## Prerequisites

- Kubernetes cluster
- Helm 3.x

## Installation

This chart is not intended for standalone use. Instead, incorporate it as a dependency in your existing Helm charts.

### Step 1: Add the Dependency

In your Helm chart's `Chart.yaml` file, add the following dependency:

```yaml
dependencies:
  - name: diagrid-dapr-injector
    version: 0.1.0
    repository: file://../charts/diagrid-dapr-injector
```

Update your Helm chart:

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
      {{ include "diagrid-dapr-injector.sidecar" (dict "podAnnotations" .Values.podAnnotations "values" .Values "namespace" (default .Release.Namespace .Values.controlPlaneNamespace)) | nindent 6 }}
      volumes:
        {{ include "diagrid-dapr-injector.volumes" . | nindent 8 }}  
```

## Configuration

The default values are defined in the `templates/_helpers.tpl` file. Key configuration options include:

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

## Support

For issues, feature requests, or questions, please file an issue in the [GitHub repository](https://github.com/diagridio/diagrid-dapr-injector).

## License

[TBD]