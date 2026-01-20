{{- define "base.serviceaccount" -}}
{{- $root := . -}}
{{- if .Values.ServiceAccount -}}
{{- range .Values.ServiceAccount }}
---
apiVersion: v1
kind: ServiceAccount
metadata:
  labels:
    {{- include "base.labels" $root | trim | nindent 4 }}
    {{- with .labels }}
    {{- toYaml . | trim | nindent 4 }}
    {{- end }}
  {{- with .annotations }}
  annotations:
    {{- toYaml . | trim | nindent 4 }}
  {{- end }}
  name: {{ .name }}
  {{- if .namespace }}
  namespace: {{ .namespace | quote }}
  {{- else if $root.Values.namespace }}
  namespace: {{ $root.Values.namespace }}
  {{- end }}
{{- end }}
{{- end }}
{{- end }}
