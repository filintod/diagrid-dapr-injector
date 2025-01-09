{{- define "dapr.serviceAddress" -}}
{{-   printf "%s.%s.svc.%s:%d" .name .controlPlaneNamespace .clusterDomain .port -}}
{{- end -}}

{{- define "dapr.headlessServiceAddressCSV" -}}
{{-   $svcCSV := list -}}
{{-   range $index, $element := until .len -}}
{{-     $svcCSV = append $svcCSV (printf "%s-%d.%s.%s.svc.%s:%d" $.name $index $.name $.controlPlaneNamespace $.clusterDomain $.port) -}}
{{-   end -}}
{{-   printf (join "," $svcCSV) -}}
{{- end -}}

{{/* "dapr.serviceAddressFromEnvSvcAddress" creates the service address from the service given as <name>:<port> */}}
{{/* Call this with: {{ include "dapr.serviceAddressFromEnvSvcAddress" (dict "svcAddress" "<name>:<port>" "controlPlaneNamespace" "<namespace>" "clusterDomain" "<clusterDomain>") }} */}}
{{- define "dapr.serviceAddressFromEnvSvcAddress" -}}
{{-   $svcAddress := splitList ":" .svcAddress }}
{{-   printf "%s.%s.svc.%s:%d" (index $svcAddress 0) .controlPlaneNamespace .clusterDomain (index $svcAddress 1) -}}
{{- end -}}

{{- define "dapr.defaultValues" -}}
dapr:
  image:
    registry: ghcr.io/dapr
    name: daprd
    tag: "1.14.4"
    pullPolicy: IfNotPresent
  controlPlaneNamespace: "dapr-system"
  controlPlaneTrustDomain: cluster.local
  trustAnchors: "" 
  
  # from dapr sidecar injector charts/dapr/sidecar-injector/values.yaml
  kubeClusterDomain: cluster.local
  sidecarDropALLCapabilities: false
  
  # from dapr global config charts/dapr/values.yaml
  actors:
    enabled: true
    serviceName: placement
    serviceAddress: "" # <name>:<port>, if not set, will default to the placement service address
  reminders:
    serviceName: "" # built-in
    serviceAddress: "" # <name>:<port>, if not set, will default to the placement service address
  scheduler: 
    enabled: true
  ha: 
    enabled: false # needed for scheduler to create list of services
  mtls: 
    enabled: true
  logAsJson: false
  prometheus:
    enabled: true
    port: 9090
  seccompProfile: ""
{{- end -}}

{{/* "diagrid.dapr.sidecar" creates the daprd container to be appended to the pod template contaienr
     It receives a dictionary with the following optional parameters:
     - .helmCtx (the parent chart context `.`)
     - .podAnnotations: the pod annotations from the deployment pod template

    Call this with:
    {{ include "diagrid.dapr.sidecar" (dict "podAnnotations" .Values.podAnnotations "values" .Values "namespace" .Release.Namespace) }}
*/}}
{{- define "diagrid.dapr.sidecar" }}
{{-   $values := mergeOverwrite (include "dapr.defaultValues" . | fromYaml) .helmCtx.Values }}
{{-   $controlPlaneNamespace := default .helmCtx.Release.Namespace $values.dapr.controlPlaneNamespace }}
{{-   $annotations := .podAnnotations | default dict }}
{{- /* Daprd Default Ports: https://github.com/dapr/dapr/blob/b4456dad3f8e085360e0aae23b6a5386d38fd67c/pkg/injector/patcher/sidecar.go#L58 */}}
{{-   $daprPublicPort       := 3501 }}
{{-   $daprHttpPort         := 3500 }}
{{-   $daprGrpcPort         := 50001 }}
{{-   $daprInternalGrpcPort := 50002 }}
{{-   $schedulerPort        := 50006 }}
{{-   $placementPort        := 50005 }}
{{-   $daprMetricsPort      := $values.dapr.prometheus.port | default 9090 }}
{{- /* Dapr services address https://github.com/dapr/dapr/blob/68d9f898f25d7c3762b747f6c4a49be8e7b48eda/pkg/injector/patcher/services.go#L28  */}}
{{-   $placementServiceAddress     := include "dapr.serviceAddress" (dict "name" "dapr-placement-server" "controlPlaneNamespace" $controlPlaneNamespace "clusterDomain" $values.dapr.kubeClusterDomain "port" $placementPort) }}
{{-   $daprSchedulerServiceAddress := include "dapr.serviceAddress" (dict "name" "dapr-scheduler-server" "controlPlaneNamespace" $controlPlaneNamespace "clusterDomain" $values.dapr.kubeClusterDomain "port" $schedulerPort) }}
{{-   $daprAPIServerServiceAddress := include "dapr.serviceAddress" (dict "name" "dapr-api"              "controlPlaneNamespace" $controlPlaneNamespace "clusterDomain" $values.dapr.kubeClusterDomain "port" 443) }}
{{-   $daprSentryServiceAddress    := include "dapr.serviceAddress" (dict "name" "dapr-sentry"           "controlPlaneNamespace" $controlPlaneNamespace "clusterDomain" $values.dapr.kubeClusterDomain "port" 443) }}
{{- /* Special handling for placement/actors/reminders service address */}}
{{-   $placementAddress := index $annotations "dapr.io/placement-host-address" }}
{{-   $actorsService := "" }}
{{-   $remindersService := "" }}
{{-   if not $placementAddress }}
{{-     $actorsSvcName := "" }}
{{-     $actorsSvc := "" }}
{{-     if eq $values.dapr.actors.serviceName "placement" }}
{{-       $placementAddress = $placementServiceAddress }}
{{-     else }}
{{-       $actorsService = printf "%s:%s" $actorsSvcName $daprSchedulerServiceAddress }}
{{-     end }}
{{-   end }}
{{-   if $values.dapr.reminders.serviceName }}
{{-     $remindersService = printf "%s:%s" $values.dapr.reminders.serviceName (ternary $placementServiceAddress $daprSchedulerServiceAddress (eq $values.dapr.reminders.serviceName "placement")) }}
{{-   end }}
{{-   $daprdImage := index $annotations "dapr.io/sidecar-image" }}
{{-   if not $daprdImage }}
{{-     $daprdImage = printf "%s/%s:%s" ($values.dapr.image.registry | default "ghcr.io/dapr") ($values.dapr.image.name | default "daprd") (required "dapr.image.tag is required" $values.dapr.image.tag) }}
{{-   end }}
- name: daprd
  image: {{ $daprdImage }}
  imagePullPolicy: {{ $values.dapr.image.pullPolicy | default "IfNotPresent" }}
  args:
  - /daprd
  - --dapr-http-port={{ $daprHttpPort }}
  - --dapr-grpc-port={{ $daprGrpcPort }}
  - --dapr-internal-grpc-port={{ $daprInternalGrpcPort }}
  - --dapr-public-port={{ $daprPublicPort }}
  - --app-id={{ index $annotations "dapr.io/app-id" }}
  - --mode=kubernetes
  - --log-level={{ index $annotations "dapr.io/log-level" | default "info" }}  
  - --dapr-listen-addresses={{ index $annotations "dapr.io/sidecar-listen-addresses" | default "[::1],127.0.0.1" }}  
  - --sentry-address={{ $daprSentryServiceAddress }}
  - --control-plane-address={{ $daprAPIServerServiceAddress }}
  {{- if eq (index $annotations "dapr.io/log-as-json" | default "false") "true" }}
  - --log-as-json
  {{- end }}
  {{- if index $annotations "dapr.io/app-port" }}
  - --app-port={{ index $annotations "dapr.io/app-port" }}
  {{- end }}
  {{- if or (eq (index $annotations "dapr.io/enable-metrics") "true") $values.dapr.prometheus.enabled }}
  - --enable-metrics
  - --metrics-port={{ index $annotations "dapr.io/metrics-port" | default $values.dapr.prometheus.port }}
  {{- end }}
  {{- if index $annotations "dapr.io/config" }}
  - --config={{ index $annotations "dapr.io/config" }}
  {{- end }}
  {{- if index $annotations "dapr.io/app-channel-address" }}
  - --app-channel-address={{ index $annotations "dapr.io/app-channel-address" }}
  {{- end }}
  - --app-protocol={{ index $annotations "dapr.io/app-protocol" | default "http" }}
  {{- if $placementAddress }}
  - --placement-host-address={{ $placementAddress }}
  {{- else if $actorsService }}
  - --actors-services={{ $actorsService }}
  {{- end }}
  {{- if $remindersService }}
  - --reminders-service={{ $remindersService }}
  {{- end }}
  {{- if ne (index $annotations "dapr.io/enable-api-logging" | default "false") "false" }}
  - --enable-api-logging={{ index $annotations "dapr.io/enable-api-logging" }}
  {{- end }}
  {{- if eq (index $annotations "dapr.io/enable-profiling" | default "false") "true" }}
  - --enable-profiling
  {{- end }}
  {{- if index $annotations "dapr.io/http-max-request-size" }}
  - --http-max-request-size={{ index $annotations "dapr.io/http-max-request-size" }}
  {{- end }}
  {{- if index $annotations "dapr.io/http-read-buffer-size"  }}
  - --http-read-buffer-size={{ index $annotations "dapr.io/http-read-buffer-size" }}
  {{- end }}
  {{- if eq (index $annotations "dapr.io/log-as-json" | default "false") "true" }}
  - --log-as-json
  {{- end }}
  {{- if ne (index $annotations "dapr.io/app-max-concurrency" | default "-1") "-1" }}
  - --app-max-concurrency={{ index $annotations "dapr.io/app-max-concurrency" }}
  {{- end }}
  {{- if index $annotations "dapr.io/scheduler-host-address" }}
  - --scheduler-host-address={{ index $annotations "dapr.io/scheduler-host-address" }}
  {{- end }}
  {{- if eq (index $annotations "dapr.io/enable-app-health-check" | default "false") "true" }}
  - --enable-app-health-check
  {{- end }}
  {{- if ne (index $annotations "dapr.io/app-health-check-path" | default "/healthz") "/healthz" }}
  - --app-health-check-path={{ index $annotations "dapr.io/app-health-check-path" }}
  {{- end }}
  {{- if ne (index $annotations "dapr.io/app-health-probe-interval" | default "5") "5" }}
  - --app-health-probe-interval={{ index $annotations "dapr.io/app-health-probe-interval" }}
  {{- end }}
  {{- if ne (index $annotations "dapr.io/app-health-probe-timeout" | default "500") "500" }}
  - --app-health-probe-timeout={{ index $annotations "dapr.io/app-health-probe-timeout" }}
  {{- end }}
  {{- if ne (index $annotations "dapr.io/app-health-threshold" | default "3") "3" }}
  - --app-health-threshold={{ index $annotations "dapr.io/app-health-threshold" }}
  {{- end }}
  {{- if index $annotations "dapr.io/max-body-size" }}
  - --max-body-size={{ index $annotations "dapr.io/max-body-size" }}
  {{- end }}
  {{- if index $annotations "dapr.io/read-buffer-size" }}
  - --read-buffer-size={{ index $annotations "dapr.io/read-buffer-size" }}
  {{- end }}
  {{- if index $annotations "dapr.io/block-shutdown-duration" }}
  - --block-shutdown-duration={{ index $annotations "dapr.io/block-shutdown-duration" }}
  {{- end }}
  {{- if eq (index $annotations "dapr.io/disable-builtin-k8s-secret-store" | default "false") "true" }}
  - --disable-builtin-k8s-secret-store
  {{- end }}
  {{- if $values.dapr.mtls.enabled }}
  - --enable-mtls
  {{- end }}
  {{- if semverCompare ">=1.14.0" $values.dapr.image.tag }}
  - --dapr-graceful-shutdown-seconds={{ index $annotations "dapr.io/graceful-shutdown-seconds" | default "-1" }}
  {{- end }}
  env:
  - name: NAMESPACE
    valueFrom:
      fieldRef:
        fieldPath: metadata.namespace
  - name: DAPR_TRUST_ANCHORS
    {{- if $values.dapr.trustAnchors }}
    value: |
      {{ $values.dapr.trustAnchors | nindent 6 | trim}}
    {{- else }}
    valueFrom:
      secretKeyRef:
        name: dapr-trust-bundle
        key: ca.crt
    {{- end }}
  - name: POD_NAME
    valueFrom:
      fieldRef:
        apiVersion: v1
        fieldPath: metadata.name
  - name: DAPR_CONTROLPLANE_NAMESPACE
    value: {{ $controlPlaneNamespace }}
  - name: DAPR_CONTROLPLANE_TRUST_DOMAIN
    value: {{ required "controlPlaneTrustDomain is required" $values.dapr.controlPlaneTrustDomain }}
  {{- if index $annotations "dapr.io/app-token-secret" }}
  - name: APP_API_TOKEN
    valueFrom:
      secretKeyRef:
        name: {{ index $annotations "dapr.io/app-token-secret" }}
        key: token
  {{- end }}
  {{- if index $annotations "dapr.io/api-token-secret" }}
  - name: DAPR_API_TOKEN
    valueFrom:
      secretKeyRef:
        name: {{ index $annotations "dapr.io/api-token-secret" }}
        key: token
  {{- end }}
  {{- if index $annotations "dapr.io/env" }}
  {{-   range split "," (index $annotations "dapr.io/env") }}
  {{- $pair := split "=" . }}
  - name: {{ $pair._0 | trim | quote }}
    value: {{ $pair._1 | trim | quote }}
  {{-   end }}
  {{- end }}
  {{- if and (semverCompare ">=1.14.0" $values.dapr.image.tag) ($values.dapr.scheduler.enabled) }}
  - name: DAPR_SCHEDULER_HOST_ADDRESS
    {{- if $values.dapr.ha.enabled }}
    value: {{ include "dapr.headlessServiceAddressCSV" (dict "name" "dapr-scheduler-server" "controlPlaneNamespace" $controlPlaneNamespace "clusterDomain" $values.dapr.kubeClusterDomain "len" 3 "port" $schedulerPort) }}
    {{- else }}
    value: {{ include "dapr.headlessServiceAddressCSV" (dict "name" "dapr-scheduler-server" "controlPlaneNamespace" $controlPlaneNamespace "clusterDomain" $values.dapr.kubeClusterDomain "len" 1 "port" $schedulerPort) }}
    {{- end }}
  {{- end }}
  livenessProbe:
    httpGet:
      path: /v1.0/healthz
      port: {{ $daprPublicPort }}
      scheme: HTTP
    initialDelaySeconds: {{ (index $annotations "dapr.io/sidecar-liveness-probe-delay-seconds" | default "3" ) | int }}
    timeoutSeconds: {{ (index $annotations "dapr.io/sidecar-liveness-probe-timeout-seconds" | default "3" ) | int }}
    periodSeconds: {{ (index $annotations "dapr.io/sidecar-liveness-probe-period-seconds" | default "6" ) | int }}
    failureThreshold: {{ (index $annotations "dapr.io/sidecar-liveness-probe-threshold" | default "3" ) | int }}
  readinessProbe:
    httpGet:
      path: /v1.0/healthz
      port: {{ $daprPublicPort }}
      scheme: HTTP
    initialDelaySeconds: {{ (index $annotations "dapr.io/sidecar-readiness-probe-delay-seconds" | default "3" ) | int }}
    timeoutSeconds: {{ (index $annotations "dapr.io/sidecar-readiness-probe-timeout-seconds" | default "3" ) | int }}
    periodSeconds: {{ (index $annotations "dapr.io/sidecar-readiness-probe-period-seconds" | default "6" ) | int }}
    failureThreshold: {{ (index $annotations "dapr.io/sidecar-readiness-probe-threshold" | default "3" ) | int }}
  ports:
  - containerPort: {{ $daprHttpPort }}
    name: dapr-http
    protocol: TCP
  - containerPort: {{ $daprGrpcPort }}
    name: dapr-grpc
    protocol: TCP
  - containerPort: {{ $daprInternalGrpcPort }}
    name: dapr-internal
    protocol: TCP
  - containerPort: {{ index $annotations "dapr.io/metrics-port" | default $daprMetricsPort }}
    name: dapr-metrics
    protocol: TCP
  securityContext:
    allowPrivilegeEscalation: false
    readOnlyRootFilesystem: true
    runAsNonRoot: true
  {{- if (index $annotations "dapr.io/sidecar-seccomp-profile-type" | default $values.dapr.seccompProfile) }}
    seccompProfile:
      type: {{ index $annotations "dapr.io/sidecar-seccomp-profile-type" | default $values.dapr.seccompProfile }}
  {{- end }}
  {{- if $values.dapr.sidecarDropALLCapabilities }}
    capabilities:
      drop: ["ALL"]
  {{- end }}
  {{- if or (index $annotations "dapr.io/sidecar-cpu-limit") (index $annotations "dapr.io/sidecar-memory-limit") (index $annotations "dapr.io/sidecar-cpu-request") (index $annotations "dapr.io/sidecar-memory-request") }}
  resources:
    {{- if or (index $annotations "dapr.io/sidecar-cpu-limit") (index $annotations "dapr.io/sidecar-memory-limit") }}
    limits:
      {{- if index $annotations "dapr.io/sidecar-cpu-limit" }}
      cpu: {{ index $annotations "dapr.io/sidecar-cpu-limit" }}
      {{- end }}
      {{- if index $annotations "dapr.io/sidecar-memory-limit" }}
      memory: {{ index $annotations "dapr.io/sidecar-memory-limit" }}
      {{- end }}
    {{- end }}
    {{- if or (index $annotations "dapr.io/sidecar-cpu-request") (index $annotations "dapr.io/sidecar-memory-request") }}
    requests:
      {{- if index $annotations "dapr.io/sidecar-cpu-request" }}
      cpu: {{ index $annotations "dapr.io/sidecar-cpu-request" }}
      {{- end }}
      {{- if index $annotations "dapr.io/sidecar-memory-request" }}
      memory: {{ index $annotations "dapr.io/sidecar-memory-request" }}
      {{- end }}
    {{- end }}
  {{- end }}
  volumeMounts:
  - mountPath: /var/run/secrets/dapr.io/sentrytoken
    name: dapr-identity-token
    readOnly: true
  {{- if index $annotations "dapr.io/volume-mounts" }}
  {{-   range split "," (index $annotations "dapr.io/volume-mounts") }}
  {{-   $mount := split ":" . }}
  - name: {{ $mount._0 | trim }}
    mountPath: {{ $mount._1 | trim }}
    readOnly: true
  {{-   end }}
  {{- end }}
  {{- if index $annotations "dapr.io/volume-mounts-rw" }}
  {{-   range split "," (index $annotations "dapr.io/volume-mounts-rw") }}
  {{-     $mount := split ":" . }}
  - name: {{ $mount._0 | trim }}
    mountPath: {{ $mount._1 | trim }}
  {{-   end }}
  {{- end }}
{{- end }}

{{- define "diagrid.dapr.identity-token-volume" }}
{{-   $values := mergeOverwrite (include "dapr.defaultValues" . | fromYaml) .Values }}
{{-   $controlPlaneNamespace := default .Release.Namespace $values.dapr.controlPlaneNamespace }}
- name: dapr-identity-token
  projected:
    defaultMode: 420
    sources:
    - serviceAccountToken:
        path: token
        expirationSeconds: 7200
        audience: spiffe://{{ $values.dapr.controlPlaneTrustDomain }}/ns/{{ $controlPlaneNamespace }}/dapr-sentry
{{- end }}
