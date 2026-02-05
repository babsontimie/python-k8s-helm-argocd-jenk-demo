{{- define "python-k8s-demo.name" -}}
python-k8s-demo
{{- end }}

{{- define "python-k8s-demo.labels" -}}
app.kubernetes.io/name: {{ include "python-k8s-demo.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
