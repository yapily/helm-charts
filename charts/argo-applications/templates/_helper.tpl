{{- define "filterEnabledApps" -}}
{{- $enabled := list }}
{{- range . }}
{{- if ne (default true .enabled) false }}
{{- $enabled = append $enabled . }}
{{- end }}
{{- end }}
{{- $enabled | toYaml }}
{{- end -}}