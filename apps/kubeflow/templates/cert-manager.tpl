{{ if .Values.certManager.enabled -}}
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: cert-manager
  namespace: argocd
  annotations:
    argocd.argoproj.io/sync-wave: "2"
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
{{ .Values.certManager.spec | toYaml | indent 2}}
{{- end -}}
