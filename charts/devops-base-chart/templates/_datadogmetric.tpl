{{/*
DatadogMetric template for the library chart.
Consuming charts invoke this with: {{ include "devops-base.datadogmetric" . }}
*/}}
{{- define "devops-base.datadogmetric" -}}
{{- if and .Values.autoscaling.enabled .Values.autoscaling.datadogMetric.enabled }}
apiVersion: datadoghq.com/v1alpha1
kind: DatadogMetric
metadata:
  name: {{ include "devops-base.fullname" . }}-latency
  labels:
    {{- include "devops-base.labels" . | nindent 4 }}
spec:
  query: {{ .Values.autoscaling.datadogMetric.query | quote }}
{{- end }}
{{- end }}
