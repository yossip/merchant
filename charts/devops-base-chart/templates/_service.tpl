{{/*
Service template for the library chart.
Consuming charts invoke this with: {{ include "devops-base.service" . }}
*/}}
{{- define "devops-base.service" -}}
apiVersion: v1
kind: Service
metadata:
  name: {{ include "devops-base.fullname" . }}
  labels:
    {{- include "devops-base.labels" . | nindent 4 }}
spec:
  type: {{ .Values.service.type }}
  ports:
    - port: {{ .Values.service.port }}
      targetPort: http
      protocol: TCP
      name: http
  selector:
    {{- include "devops-base.selectorLabels" . | nindent 4 }}
{{- end }}
