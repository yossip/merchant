{{/*
HPA template for the library chart.
Consuming charts invoke this with: {{ include "devops-base.hpa" . }}
*/}}
{{- define "devops-base.hpa" -}}
{{- if .Values.autoscaling.enabled }}
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: {{ include "devops-base.fullname" . }}
  labels:
    {{- include "devops-base.labels" . | nindent 4 }}
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: {{ include "devops-base.fullname" . }}
  minReplicas: {{ .Values.autoscaling.minReplicas }}
  maxReplicas: {{ .Values.autoscaling.maxReplicas }}
  metrics:
    {{- if and .Values.autoscaling.datadogMetric.enabled .Values.autoscaling.datadogMetric.targetValue }}
    - type: External
      external:
        metric:
          name: datadogmetric@default:{{ include "devops-base.fullname" . }}-latency
        target:
          type: AverageValue
          value: {{ .Values.autoscaling.datadogMetric.targetValue | quote }}
    {{- else }}
    {{- if .Values.autoscaling.targetCPUUtilizationPercentage }}
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: {{ .Values.autoscaling.targetCPUUtilizationPercentage }}
    {{- end }}
    {{- if .Values.autoscaling.targetMemoryUtilizationPercentage }}
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: {{ .Values.autoscaling.targetMemoryUtilizationPercentage }}
    {{- end }}
    {{- end }}
{{- end }}
{{- end }}
