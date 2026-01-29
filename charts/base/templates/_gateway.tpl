
{{- define "base.gateway" -}}
{{- $root := . -}}
{{- $fullName := include "base.fullname" . -}}

{{- $defaultGatewayValues := (.Values.gateway | default dict) -}}
{{- $gatewayMap := list -}}
{{- if $defaultGatewayValues.enabled -}}
  {{- $gatewayMap = list $defaultGatewayValues -}}
{{- end -}}
{{- if .Values.gatewayList -}}
  {{- range $item := .Values.gatewayList -}}
    {{- if $item.enabled -}}
      {{- $gatewayMap = append $gatewayMap $item -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{- range $index, $gatewayValues := $gatewayMap }}
{{- $gwName := "" -}}
{{- if $gatewayValues.name -}}
  {{- $gwName = $gatewayValues.name -}}
{{- else -}}
  {{- if eq $index 0 -}}
    {{- $gwName = $fullName -}}
  {{- else -}}
    {{- $gwName = printf "%s-%s" $fullName (toString (add $index 1)) -}}
  {{- end -}}
{{- end -}}

---
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: {{ $gwName }}
  {{- if $gatewayValues.namespace }}
  namespace: {{ $gatewayValues.namespace }}
  {{- else if $root.Values.namespace }}
  namespace: {{ $root.Values.namespace }}
  {{- end }}
  labels:
    {{- include "base.commonLabels" $root | trim | nindent 4 }}
    {{- with $gatewayValues.labels }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
  {{- with $gatewayValues.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  gatewayClassName: {{ $gatewayValues.gatewayClassName | default "eg" | quote }}

  {{- if $gatewayValues.addresses }}
  addresses:
    {{- toYaml $gatewayValues.addresses | nindent 4 }}
  {{- end }}

  {{- if $gatewayValues.listeners }}
  listeners:
    {{- toYaml $gatewayValues.listeners | nindent 4 }}
  {{- else }}
  listeners:
    - name: http
      protocol: HTTP
      port: {{ $gatewayValues.httpPort | default 80 }}
      {{- with $gatewayValues.hostname }}
      hostname: {{ . | quote }}
      {{- end }}
      {{- with $gatewayValues.allowedRoutes }}
      allowedRoutes:
        {{- toYaml . | nindent 8 }}
      {{- end }}

    {{- $tlsSecret := "" -}}
    {{- if and $gatewayValues.tls $gatewayValues.tls.secretName -}}
      {{- $tlsSecret = $gatewayValues.tls.secretName -}}
    {{- else if and $root.Values.tls $root.Values.tls.default -}}
      {{- $tlsSecret = $root.Values.tls.default -}}
    {{- end -}}

    {{- if $tlsSecret }}
    - name: https
      protocol: HTTPS
      port: {{ $gatewayValues.httpsPort | default 443 }}
      {{- with $gatewayValues.hostname }}
      hostname: {{ . | quote }}
      {{- end }}
      {{- with $gatewayValues.allowedRoutes }}
      allowedRoutes:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      tls:
        mode: Terminate
        certificateRefs:
          - kind: Secret
            group: ""
            name: {{ $tlsSecret | quote }}
    {{- end }}
  {{- end }}
{{- end }}
{{- end }}
