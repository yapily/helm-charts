{{- define "base.flagger" -}}
{{- if .Values.flagger }}
---
apiVersion: {{ .Values.flagger.apiVersion | default "flagger.app/v1beta1" }}
kind: Canary
metadata:
  {{- if .Values.flagger.name }}
  name: {{ .Values.flagger.name }}
  {{- else }}
  name: {{ include "base.fullname" . }}
  {{- end }}
{{- with .Values.flagger.spec }}
spec:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- end }}
{{- end }}