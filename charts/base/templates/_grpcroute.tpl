{{- define "base.grpcroute" -}}
{{- $root := . -}}
{{- $fullName := include "base.fullname" . -}}
{{- $svcPort := include "base.servicePortDefaultNum" . -}}
{{- $serviceValues := .Values.service | default dict -}}
{{- $svcName := ($serviceValues.name | default $fullName) -}}

{{- $defaultRouteValues := (.Values.grpcRoute | default dict) -}}
{{- $routeMap := list -}}
{{- if $defaultRouteValues.enabled -}}
  {{- $routeMap = list $defaultRouteValues -}}
{{- end -}}
{{- if .Values.grpcRouteList -}}
  {{- range $item := .Values.grpcRouteList -}}
    {{- if $item.enabled -}}
      {{- $routeMap = append $routeMap $item -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{- range $rIndex, $routeValues := $routeMap }}
{{- $routeName := "" -}}
{{- if $routeValues.name -}}
  {{- $routeName = $routeValues.name -}}
{{- else -}}
  {{- if eq $rIndex 0 -}}
    {{- $routeName = printf "%s-grpc" $fullName -}}
  {{- else -}}
    {{- $routeName = printf "%s-grpc-%s" $fullName (toString (add $rIndex 1)) -}}
  {{- end -}}
{{- end -}}

---
apiVersion: gateway.networking.k8s.io/v1
kind: GRPCRoute
metadata:
  name: {{ $routeName }}
  {{- if $routeValues.namespace }}
  namespace: {{ $routeValues.namespace }}
  {{- else if $root.Values.namespace }}
  namespace: {{ $root.Values.namespace }}
  {{- end }}
  labels:
    {{- include "base.commonLabels" $root | trim | nindent 4 }}
    {{- with $routeValues.labels }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
  {{- with $routeValues.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  parentRefs:
    {{- if $routeValues.parentRefs }}
    {{- toYaml $routeValues.parentRefs | nindent 4 }}
    {{- else }}
    - name: {{ $routeValues.gatewayName | default ($root.Values.gateway.name | default "eg") | quote }}
      {{- with ($routeValues.gatewayNamespace | default $root.Values.gateway.namespace) }}
      namespace: {{ . | quote }}
      {{- end }}
      {{- with $routeValues.sectionName }}
      sectionName: {{ . | quote }}
      {{- end }}
    {{- end }}

  {{- with $routeValues.hostnames }}
  hostnames:
    {{- range . }}
    - {{ . | quote }}
    {{- end }}
  {{- end }}

  rules:
    {{ $rules := ($routeValues.rules | default list) }}
    {{ range $rule := $rules }}

    {{- $portVal := ($rule.servicePort | default $svcPort) -}}
    {{- if and (not $rule.backendRefs) (not (regexMatch "^[0-9]+$" (toString $portVal))) -}}
      {{- fail (printf "GRPCRoute backendRefs.port must be numeric (got %v). Named ports aren't supported here." $portVal) -}}
    {{- end -}}

    - {{- with $rule.matches }}
      matches:
        {{- toYaml . | nindent 8 }}
      {{- end }}

      {{- with $rule.filters }}
      filters:
        {{- toYaml . | nindent 8 }}
      {{- end }}

      backendRefs:
        {{- if $rule.backendRefs }}
        {{- toYaml $rule.backendRefs | nindent 8 }}
        {{- else }}
        - group: ""
          kind: Service
          name: {{ ($rule.serviceName | default $svcName) | quote }}
          port: {{ $portVal }}
          {{- with $rule.weight }}
          weight: {{ . }}
          {{- else }}
          weight: 1
          {{- end }}
        {{- end }}
    {{- end }}
{{- end }}
{{- end }}
