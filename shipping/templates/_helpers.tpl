{{- define "shipping.name" -}}
{{- .Values.microServiceName }}
{{- end }}

{{- define "shipping.fullname" -}}
{{- .Values.microServiceName }}
{{- end }}

{{- define "shipping.labels" -}}
app: {{ .Values.appName }}
env: {{ .Values.env }}
{{- end }}

{{- define "shipping.selectorLabels" -}}
app: {{ .Values.appName }}
{{- end }}

{{- define "shipping.serviceAccountName" -}}
{{- .Values.config.serviceAccountName | default "default" }}
{{- end }}

{{/*
Copy the selected env block (dev/qa/stage/prod) onto .Values.config.
Must be included at the top of every template that reads config.
*/}}
{{- define "shipping.set.env.variables" -}}
{{- if eq .Values.env "prod" -}}
{{- $_ := mergeOverwrite .Values.config .Values.prod -}}
{{- else if eq .Values.env "qa" -}}
{{- $_ := mergeOverwrite .Values.config .Values.qa -}}
{{- else if eq .Values.env "stage" -}}
{{- $_ := mergeOverwrite .Values.config .Values.stage -}}
{{- else -}}
{{- $_ := mergeOverwrite .Values.config .Values.dev -}}
{{- end -}}
{{- end -}}
