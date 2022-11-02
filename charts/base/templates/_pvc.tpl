{{- define "base.pvc" -}}
{{- if .Values.persistentVolumeClaims }}
{{- $root := . -}}
{{- range .Values.persistentVolumeClaims }}
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: {{ .name }}
  labels:
    {{- include "base.commonLabels" $root | trim | nindent 4 }}
spec:
  {{- if .volumeName  }}
  volumeName: {{ .volumeName }}
  storageClassName: ""
  {{- else }}
  storageClassName: {{ .storageClassName | default "standard" }}
  {{- end }}
  resources:
    requests:
      storage: {{ .storage | default "10Gi" }}
  {{- if .accessModes  }}
  {{- with .accessModes }}
  accessModes:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- else }}
  accessModes:
    - ReadWriteOnce
  {{- end }}
{{- end }}
{{- end }}
{{- end }}