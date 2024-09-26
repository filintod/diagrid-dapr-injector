// annotations in golang

type SidecarConfig struct {
	GetInjectedComponentContainers GetInjectedComponentContainersFn

	Mode                        injectorConsts.DaprMode `default:"kubernetes"`
	Namespace                   string
	MTLSEnabled                 bool
	Identity                    string
	IgnoreEntrypointTolerations []corev1.Toleration
	ImagePullPolicy             corev1.PullPolicy
	OperatorAddress             string
	SentryAddress               string
	RunAsNonRoot                bool
	RunAsUser                   *int64
	RunAsGroup                  *int64
	EnableK8sDownwardAPIs       bool
	ReadOnlyRootFilesystem      bool
	SidecarDropALLCapabilities  bool
	DisableTokenVolume          bool
	CurrentTrustAnchors         []byte
	ControlPlaneNamespace       string
	ControlPlaneTrustDomain     string
	ActorsService               string
	RemindersService            string
	SentrySPIFFEID              string
	SidecarHTTPPort             int32 `default:"3500"`
	SidecarAPIGRPCPort          int32 `default:"50001"`
	SidecarInternalGRPCPort     int32 `default:"50002"`
	SidecarPublicPort           int32 `default:"3501"`

	Enabled                             bool    `annotation:"dapr.io/enabled"`
	AppPort                             int32   `annotation:"dapr.io/app-port"`
	Config                              string  `annotation:"dapr.io/config"`
	AppProtocol                         string  `annotation:"dapr.io/app-protocol" default:"http"`
	AppSSL                              bool    `annotation:"dapr.io/app-ssl"` // TODO: Deprecated in Dapr 1.11; remove in a future Dapr version
	AppID                               string  `annotation:"dapr.io/app-id"`
	EnableProfiling                     bool    `annotation:"dapr.io/enable-profiling"`
	LogLevel                            string  `annotation:"dapr.io/log-level" default:"info"`
	APITokenSecret                      string  `annotation:"dapr.io/api-token-secret"`
	AppTokenSecret                      string  `annotation:"dapr.io/app-token-secret"`
	LogAsJSON                           bool    `annotation:"dapr.io/log-as-json"`
	AppMaxConcurrency                   *int    `annotation:"dapr.io/app-max-concurrency"`
	EnableMetrics                       bool    `annotation:"dapr.io/enable-metrics" default:"true"`
	SidecarMetricsPort                  int32   `annotation:"dapr.io/metrics-port" default:"9090"`
	EnableDebug                         bool    `annotation:"dapr.io/enable-debug" default:"false"`
	SidecarDebugPort                    int32   `annotation:"dapr.io/debug-port" default:"40000"`
	Env                                 string  `annotation:"dapr.io/env"`
	SidecarCPURequest                   string  `annotation:"dapr.io/sidecar-cpu-request"`
	SidecarCPULimit                     string  `annotation:"dapr.io/sidecar-cpu-limit"`
	SidecarMemoryRequest                string  `annotation:"dapr.io/sidecar-memory-request"`
	SidecarMemoryLimit                  string  `annotation:"dapr.io/sidecar-memory-limit"`
	SidecarListenAddresses              string  `annotation:"dapr.io/sidecar-listen-addresses" default:"[::1],127.0.0.1"`
	SidecarLivenessProbeDelaySeconds    int32   `annotation:"dapr.io/sidecar-liveness-probe-delay-seconds"    default:"3"`
	SidecarLivenessProbeTimeoutSeconds  int32   `annotation:"dapr.io/sidecar-liveness-probe-timeout-seconds"  default:"3"`
	SidecarLivenessProbePeriodSeconds   int32   `annotation:"dapr.io/sidecar-liveness-probe-period-seconds"   default:"6"`
	SidecarLivenessProbeThreshold       int32   `annotation:"dapr.io/sidecar-liveness-probe-threshold"        default:"3"`
	SidecarReadinessProbeDelaySeconds   int32   `annotation:"dapr.io/sidecar-readiness-probe-delay-seconds"   default:"3"`
	SidecarReadinessProbeTimeoutSeconds int32   `annotation:"dapr.io/sidecar-readiness-probe-timeout-seconds" default:"3"`
	SidecarReadinessProbePeriodSeconds  int32   `annotation:"dapr.io/sidecar-readiness-probe-period-seconds"  default:"6"`
	SidecarReadinessProbeThreshold      int32   `annotation:"dapr.io/sidecar-readiness-probe-threshold"       default:"3"`
	SidecarImage                        string  `annotation:"dapr.io/sidecar-image"`
	SidecarSeccompProfileType           string  `annotation:"dapr.io/sidecar-seccomp-profile-type"`
	HTTPMaxRequestSize                  *int    `annotation:"dapr.io/http-max-request-size"` // Legacy flag
	MaxBodySize                         string  `annotation:"dapr.io/max-body-size"`
	HTTPReadBufferSize                  *int    `annotation:"dapr.io/http-read-buffer-size"` // Legacy flag
	ReadBufferSize                      string  `annotation:"dapr.io/read-buffer-size"`
	GracefulShutdownSeconds             int     `annotation:"dapr.io/graceful-shutdown-seconds"               default:"-1"`
	BlockShutdownDuration               *string `annotation:"dapr.io/block-shutdown-duration"`
	EnableAPILogging                    *bool   `annotation:"dapr.io/enable-api-logging"`
	UnixDomainSocketPath                string  `annotation:"dapr.io/unix-domain-socket-path"`
	VolumeMounts                        string  `annotation:"dapr.io/volume-mounts"`
	VolumeMountsRW                      string  `annotation:"dapr.io/volume-mounts-rw"`
	DisableBuiltinK8sSecretStore        bool    `annotation:"dapr.io/disable-builtin-k8s-secret-store"`
	EnableAppHealthCheck                bool    `annotation:"dapr.io/enable-app-health-check"`
	AppHealthCheckPath                  string  `annotation:"dapr.io/app-health-check-path" default:"/healthz"`
	AppHealthProbeInterval              int32   `annotation:"dapr.io/app-health-probe-interval" default:"5"`  // In seconds
	AppHealthProbeTimeout               int32   `annotation:"dapr.io/app-health-probe-timeout" default:"500"` // In milliseconds
	AppHealthThreshold                  int32   `annotation:"dapr.io/app-health-threshold" default:"3"`
	PlacementAddress                    string  `annotation:"dapr.io/placement-host-address"`
	SchedulerAddress                    string  `annotation:"dapr.io/scheduler-host-address"`
	PluggableComponents                 string  `annotation:"dapr.io/pluggable-components"`
	PluggableComponentsSocketsFolder    string  `annotation:"dapr.io/pluggable-components-sockets-folder"`
	ComponentContainer                  string  `annotation:"dapr.io/component-container"`
	InjectPluggableComponents           bool    `annotation:"dapr.io/inject-pluggable-components"`
	AppChannelAddress                   string  `annotation:"dapr.io/app-channel-address"`

	pod *corev1.Pod
}