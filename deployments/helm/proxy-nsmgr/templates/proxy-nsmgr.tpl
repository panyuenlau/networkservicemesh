---
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: proxy-nsmgr
  namespace: {{ .Release.Namespace }}
spec:
  selector:
    matchLabels:
      app: proxy-nsmgr-daemonset
  template:
    metadata:
      labels:
        app: proxy-nsmgr-daemonset
    spec:
      serviceAccount: nsmgr-acc
      containers:
        - name: proxy-nsmd
          image: {{ .Values.registry }}/{{ .Values.org }}/proxy-nsmd:{{ .Values.tag }}
          imagePullPolicy: {{ .Values.pullPolicy }}
          ports:
            - containerPort: 5006
              hostPort: 5006
          env:
            - name: INSECURE
{{- if .Values.insecure }}
              value: "true"
{{- else }}
              value: "false"
{{- end }}
            - name: PROXY_NSMD_K8S_REMOTE_PORT
              value: {{ .Values.remoteNsrPort | quote }}
        - name: proxy-nsmd-k8s
          image: {{ .Values.registry }}/{{ .Values.org }}/proxy-nsmd-k8s:{{ .Values.tag }}
          imagePullPolicy: {{ .Values.pullPolicy }}
          ports:
            - containerPort: 5005
              hostPort: 5005
          env:
            - name: INSECURE
{{- if .Values.insecure }}
              value: "true"
{{- else }}
              value: "false"
{{- end }}
            - name: NODE_NAME
              valueFrom:
                fieldRef:
                  fieldPath: spec.nodeName
{{- if .Values.global.JaegerTracing }}
            - name: TRACER_ENABLED
              value: "true"
            - name: JAEGER_AGENT_HOST
              value: jaeger.nsm-system
            - name: JAEGER_AGENT_PORT
              value: "6831"
{{- end }}
            - name: PROXY_NSMD_K8S_REMOTE_PORT
              value: {{ .Values.remoteNsrPort | quote }}
---
apiVersion: v1
kind: Service
metadata:
  name: pnsmgr-svc
  labels:
    app: proxy-nsmgr-daemonset
  namespace: {{ .Release.Namespace }}
spec:
  type: NodePort
  ports:
    - name: pnsmr
      port: 5005
      nodePort: 31505
      protocol: TCP
    - name: pnsmd
      port: 5006
      nodePort: 31506
      protocol: TCP
  selector:
    app: proxy-nsmgr-daemonset
