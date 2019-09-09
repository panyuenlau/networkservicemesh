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
      containers:
        - name: proxy-nsmd
          image: {{ .Values.registry }}/{{ .Values.org }}/proxy-nsmd:{{ .Values.tag }}
          imagePullPolicy: {{ .Values.pullPolicy }}
          ports:
            - containerPort: 5006
          env:
            - name: PROXY_NSMD_K8S_REMOTE_PORT
              value: "30505"
{{- if .Values.global.JaegerTracing }}
            - name: JAEGER_AGENT_HOST
              value: jaeger.nsm-system
            - name: JAEGER_AGENT_PORT
              value: "6831"
{{- end }}
        - name: proxy-nsmd-k8s
          image: {{ .Values.registry }}/{{ .Values.org }}/proxy-nsmd-k8s:{{ .Values.tag }}
          imagePullPolicy: {{ .Values.pullPolicy }}
          ports:
            - containerPort: 5005
          env:
            - name: NODE_NAME
              valueFrom:
                fieldRef:
                  fieldPath: spec.nodeName
            - name: PROXY_NSMD_K8S_REMOTE_PORT
              value: "30505"
{{- if .Values.global.JaegerTracing }}
            - name: JAEGER_AGENT_HOST
              value: jaeger.nsm-system
            - name: JAEGER_AGENT_PORT
              value: "6831"
{{- end }}
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
    - name: pnsmd
      port: 5006
      nodePort: 30506
      protocol: TCP
    - name: pnsr
      port: 5005
      nodePort: 30505
      protocol: TCP
  selector:
    app: proxy-nsmgr-daemonset
