{{/*
ServiceAccount template for the library chart.
Consuming charts invoke this with: {{ include "devops-base.serviceaccount" . }}
*/}}
{{- define "devops-base.serviceaccount" -}}
{{- if .Values.serviceAccount.create -}}
apiVersion: v1
kind: ServiceAccount
metadata:
  name: {{ include "devops-base.serviceAccountName" . }}
  labels:
    {{- include "devops-base.labels" . | nindent 4 }}
  {{- with .Values.serviceAccount.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
automountServiceAccountToken: {{ .Values.serviceAccount.automount }}
{{- end }}
{{- end }}
