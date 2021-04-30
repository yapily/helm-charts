{{- define "base.argoRollouts" -}}
{{- $root := . -}}
{{- range $deploymentName, $deploymentValuesOverride := .Values.deployments }}
{{- $deploymentValues := merge dict $deploymentValuesOverride $root -}}
{{- if $deploymentValues.enabled }}
{{- if $deploymentValues.Values.argo.rollouts.enabled }}
---
apiVersion: {{ $deploymentValues.Values.apiVersion | default "argoproj.io/v1alpha1" }}
kind: {{ $deploymentValues.Values.kind | default "Rollout" }}
metadata:
  name: {{ include "base.fullname" $deploymentValues }}
  {{- if $deploymentValues.Values.autoscaling.enabled }}
  replicas: {{ $deploymentValues.Values.autoscaling.minReplicas }}
  {{- else }}
  replicas: {{ $deploymentValues.Values.replicaCount }}
  {{- end }}
  workloadRef:
    apiVersion: {{ $deploymentValues.Values.apiVersion | default "apps/v1" }}
    kind: {{ $deploymentValues.Values.kind | default "Deployment" }}
    name: {{ include "base.fullname" $deploymentValues }}
  {{- with $deploymentValues.Values.argo.strategy }}
  strategy:
    {{- toYaml . | nindent 4 }}
  {{- end }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}