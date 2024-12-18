{{ if .Values.istioInstall.enabled }}
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: istio-install
  namespace: argocd
  annotations:
    argocd.argoproj.io/sync-wave: "10"
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
{{ .Values.istioInstall.spec | toYaml | indent 2 }}
{{- end -}}
