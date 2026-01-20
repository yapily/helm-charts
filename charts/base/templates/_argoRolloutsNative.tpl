{{- define "base.argoRolloutsNative" -}}
{{- if and .Values.argo.rollouts.enabled (eq .Values.argo.rollouts.type "Native") }}
{{- if not .Values.statefulSet }}
{{- $root := . -}}
---
apiVersion: {{ $root.Values.argo.rollouts.apiVersion | default "argoproj.io/v1alpha1" }}
kind: {{ $root.Values.argo.rollouts.kind | default "Rollout" }}
metadata:
  name: {{ include "base.fullname" $root }}
  {{- if $root.Values.namespace }}
  namespace: {{ $root.Values.namespace }}
  {{- end }}
  labels:
    {{- include "base.labels" $root | trim | nindent 4 }}
    {{- with $root.Values.labelsDeployment }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
  {{- if $root.Values.annotations }}
  annotations:
    {{- include "base.valuesPairs" $root.Values.annotations | trim | nindent 4 }}
  {{- end }}
spec:
  {{- if $root.Values.keda.enabled }}
  replicas: {{ $root.Values.keda.minReplicaCount | default 0 }}
  {{- else if $root.Values.autoscaling.enabled }}
  replicas: {{ $root.Values.autoscaling.minReplicas }}
  {{- else }}
  replicas: {{ $root.Values.replicas }}
  {{- end }}
  revisionHistoryLimit: {{ $root.Values.revisionHistoryLimit | default 10 }}
  {{- with $root.Values.argo.rollouts.strategy }}
  strategy:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- if $root.Values.minReadySeconds }}
  minReadySeconds: {{ $root.Values.minReadySeconds }}
  {{- end }}
  {{- if $root.Values.progressDeadlineSeconds }}
  progressDeadlineSeconds: {{ $root.Values.progressDeadlineSeconds }}
  {{- end }}
  selector:
    matchLabels:
      {{- include "base.selectorLabels" $root | trim | nindent 6 }}
  template:
    metadata:
      {{- if or $root.Values.prometheusScrape $root.Values.podAnnotations }}
      annotations:
        {{- if $root.Values.prometheusScrape }}
        prometheus.io/path: {{ $root.Values.prometheusScrapePath | quote }}
        prometheus.io/port: {{ $root.Values.prometheusScrapePort | quote }}
        prometheus.io/scrape: "true"
        {{- end }}
        {{- if $root.Values.podAnnotations }}
        {{- include "base.valuesPairs" $root.Values.podAnnotations | trim | nindent 8 }}
        {{- end }}
      {{- end }}
      labels:
        {{- with $root.Values.podLabels }}
        {{- toYaml . | nindent 8 }}
        {{- end }}
        {{- include "base.selectorLabels" $root | trim | nindent 8 }}
    spec:
      {{- with include "base.podDefaultProperties" $root }}
      {{- . | trim | nindent 6 }}
      {{- end }}
      {{- if $root.Values.initContainers }}
      initContainers:
        {{- range $containerName, $containerValues := $root.Values.initContainers }}
        - name: {{ $containerName }}
          {{- include "base.image" (merge dict $containerValues.image $root.Values.image) | nindent 10 }}
          {{- with $containerValues.ports }}
          ports:
            {{- toYaml . | trim | nindent 12 }}
          {{- end }}
          {{- with include "base.containerDefaultProperties" $containerValues }}
          {{- . | trim | nindent 10 }}
          {{- end }}
        {{- end }}
      {{- end }}
      containers:
        - name: {{ include "base.name" $root }}
          {{- include "base.image" $root.Values.image | nindent 10 }}
          {{- with $root.Values.ports }}
          ports:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- with include "base.containerDefaultProperties" $root.Values }}
          {{- . | trim | nindent 10 }}
          {{- end }}
        {{- range $containerName, $containerValues := $root.Values.extraContainers }}
        - name: {{ $containerName }}
          {{- include "base.image" (merge dict $containerValues.image $root.Values.image) | nindent 10 }}
          {{- with $containerValues.ports }}
          ports:
            {{- toYaml . | trim | nindent 12 }}
          {{- end }}
          {{- with include "base.containerDefaultProperties" $containerValues }}
          {{- . | trim | nindent 10 }}
          {{- end }}
        {{- end }}
      {{- with include "base.volumes" $root }}
      {{- . | trim | nindent 6 }}
      {{- end }}
{{- end }}
{{- end }}
{{- end }}
