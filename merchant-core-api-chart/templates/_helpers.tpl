{{/*
Merchant Core API helpers - thin wrappers that delegate to the DevOps base library.
This allows the application chart to use its own chart name while inheriting all logic.
*/}}

{{/*
Expand the name of the chart.
*/}}
{{- define "merchant-core-api-chart.name" -}}
{{- include "devops-base.name" . -}}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "merchant-core-api-chart.fullname" -}}
{{- include "devops-base.fullname" . -}}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "merchant-core-api-chart.chart" -}}
{{- include "devops-base.chart" . -}}
{{- end }}

{{/*
Common labels
*/}}
{{- define "merchant-core-api-chart.labels" -}}
{{- include "devops-base.labels" . -}}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "merchant-core-api-chart.selectorLabels" -}}
{{- include "devops-base.selectorLabels" . -}}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "merchant-core-api-chart.serviceAccountName" -}}
{{- include "devops-base.serviceAccountName" . -}}
{{- end }}
