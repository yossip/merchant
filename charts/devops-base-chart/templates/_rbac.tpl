{{/*
RBAC template for the library chart.
Creates a Role and RoleBinding scoped to the release namespace.
Consuming charts invoke this with: {{ include "devops-base.rbac" . }}
*/}}
{{- define "devops-base.rbac" -}}
{{- if .Values.rbac.create -}}
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: {{ include "devops-base.fullname" . }}
  labels:
    {{- include "devops-base.labels" . | nindent 4 }}
rules:
  {{- toYaml .Values.rbac.rules | nindent 2 }}
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: {{ include "devops-base.fullname" . }}
  labels:
    {{- include "devops-base.labels" . | nindent 4 }}
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: {{ include "devops-base.fullname" . }}
subjects:
  - kind: ServiceAccount
    name: {{ include "devops-base.serviceAccountName" . }}
    namespace: {{ .Release.Namespace }}
{{- end }}
{{- end }}
