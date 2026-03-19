{{- define "base.httproute" -}}
{{- $root := . -}}
{{- $fullName := include "base.fullname" . -}}
{{- $svcPort := include "base.servicePortDefaultNum" . -}}
{{- $serviceValues := .Values.service | default dict -}}
{{- $svcName := ($serviceValues.name | default $fullName) -}}

{{- $defaultRouteValues := (.Values.httpRoute | default dict) -}}
{{- $routeMap := list -}}
{{- if $defaultRouteValues.enabled -}}
  {{- $routeMap = list $defaultRouteValues -}}
{{- end -}}
{{- if .Values.httpRouteList -}}
  {{- range $item := .Values.httpRouteList -}}
    {{- if $item.enabled -}}
      {{- $routeMap = append $routeMap $item -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{- range $rIndex, $routeValues := $routeMap }}
{{- $baseName := "" -}}
{{- if $routeValues.name -}}
  {{- $baseName = $routeValues.name -}}
{{- else -}}
  {{- if eq $rIndex 0 -}}
    {{- $baseName = $fullName -}}
  {{- else -}}
    {{- $baseName = printf "%s-%s" $fullName (toString (add $rIndex 1)) -}}
  {{- end -}}
{{- end -}}

{{- $hosts := ($routeValues.hosts | default list) -}}
{{- range $hIndex, $hostValues := $hosts }}
{{- $routeName := "" -}}
{{- if eq (len $hosts) 1 -}}
  {{- $routeName = $baseName -}}
{{- else -}}
  {{- $routeName = printf "%s-%s" $baseName (toString (add $hIndex 1)) -}}
{{- end -}}
---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
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

  hostnames:
    - {{ $hostValues.host | quote }}

  rules:
    {{ $defaultList := list (dict "a" "b") }}
    {{ $hostPaths := ($hostValues.paths | default $defaultList) }}
    {{ range $p := $hostPaths }}
    {{ $pVals := mergeOverwrite (dict) (deepCopy $hostValues) $p }}

    {{- $pathVal := ($pVals.path | default "/") -}}

    {{- $matchType := "" -}}
    {{- if $pVals.pathMatchType -}}
      {{- $matchType = $pVals.pathMatchType -}}
    {{- else -}}
      {{- $pt := ($pVals.pathType | default "Prefix") -}}
      {{- if eq $pt "Exact" -}}
        {{- $matchType = "Exact" -}}
      {{- else -}}
        {{- $matchType = "PathPrefix" -}}
      {{- end -}}
    {{- end -}}

    {{- $portVal := ($pVals.servicePort | default $svcPort) -}}
    {{- if not (regexMatch "^[0-9]+$" (toString $portVal)) -}}
      {{- fail (printf "HTTPRoute backendRefs.port must be numeric (got %v). Named ports aren't supported here." $portVal) -}}
    {{- end -}}

    - matches:
        - path:
            type: {{ $matchType | quote }}
            value: {{ $pathVal | quote }}

      {{- with $pVals.filters }}
      filters:
        {{- toYaml . | nindent 8 }}
      {{- end }}

      backendRefs:
        {{- if $pVals.backendRefs }}
        {{- toYaml $pVals.backendRefs | nindent 8 }}
        {{- else }}
        - group: ""
          kind: Service
          name: {{ ($pVals.serviceName | default $svcName) | quote }}
          port: {{ $portVal }}
          {{- with $pVals.weight }}
          weight: {{ . }}
          {{- else }}
          weight: 1
          {{- end }}
        {{- end }}
    {{- end }}
{{- end }}
{{- end }}
{{- end }}
