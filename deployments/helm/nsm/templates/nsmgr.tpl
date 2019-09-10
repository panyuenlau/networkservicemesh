apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: nsmgr
  namespace: {{ .Release.Namespace }}
spec:
  selector:
    matchLabels:
      app: nsmgr-daemonset
  template:
    metadata:
      labels:
        app: nsmgr-daemonset
    spec:
      containers:
        - name: nsmdp
          image: {{ .Values.registry }}/{{ .Values.org }}/nsmdp:{{ .Values.tag }}
          imagePullPolicy: {{ .Values.pullPolicy }}
{{- if .Values.global.JaegerTracing }}
          env:
            - name: JAEGER_AGENT_HOST
              value: jaeger.nsm-system
            - name: JAEGER_AGENT_PORT
              value: "6831"
{{- end }}
          volumeMounts:
            - name: kubelet-socket
              mountPath: /var/lib/kubelet/device-plugins
            - name: nsm-socket
              mountPath: /var/lib/networkservicemesh
        - name: nsmd
          image: {{ .Values.registry }}/{{ .Values.org }}/nsmd:{{ .Values.tag }}
          imagePullPolicy: {{ .Values.pullPolicy }}
{{- if .Values.global.JaegerTracing }}
          ports:
            - containerPort: 5001
              hostPort: 5001
          env:
            - name: JAEGER_AGENT_HOST
              value: jaeger.nsm-system
            - name: JAEGER_AGENT_PORT
              value: "6831"
{{- end }}
{{- if or .Values.global.NSMApiSvc .Values.global.NSMApiSvcAddr }}
            - name: NSMD_API_ADDRESS
              value: {{ .Values.global.NSMApiSvcAddr | default "0.0.0.0:5001" | quote}}
{{- end }}
          volumeMounts:
            - name: nsm-socket
              mountPath: /var/lib/networkservicemesh
            - name: nsm-plugin-socket
              mountPath: /var/lib/networkservicemesh/plugins
          livenessProbe:
            httpGet:
              path: /liveness
              port: 5555
            initialDelaySeconds: 10
            periodSeconds: 10
            timeoutSeconds: 3
          readinessProbe:
            httpGet:
              path: /readiness
              port: 5555
            initialDelaySeconds: 10
            periodSeconds: 10
            timeoutSeconds: 3
        - name: nsmd-k8s
          image: {{ .Values.registry }}/{{ .Values.org }}/nsmd-k8s:{{ .Values.tag }}
          imagePullPolicy: {{ .Values.pullPolicy }}
          volumeMounts:
            - name: nsm-plugin-socket
              mountPath: /var/lib/networkservicemesh/plugins
          env:
            - name: NODE_NAME
              valueFrom:
                fieldRef:
                  fieldPath: spec.nodeName
{{- if .Values.global.JaegerTracing }}
            - name: JAEGER_AGENT_HOST
              value: jaeger.nsm-system
            - name: JAEGER_AGENT_PORT
              value: "6831"
{{- end }}
{{- if or .Values.global.NSRegistrySvc .Values.global.NSRegistrySvcAddr }}
            - name: NSMD_K8S_ADDRESS
              value: {{ .Values.global.NSRegistrySvcAddr | default "0.0.0.0:5000" | quote}}
{{- end }}
      volumes:
        - hostPath:
            path: /var/lib/kubelet/device-plugins
            type: DirectoryOrCreate
          name: kubelet-socket
        - hostPath:
            path: /var/lib/networkservicemesh
            type: DirectoryOrCreate
          name: nsm-socket
        - hostPath:
            path: /var/lib/networkservicemesh/plugins
            type: DirectoryOrCreate
          name: nsm-plugin-socket

{{- if or .Values.global.NSRegistrySvc .Values.global.NSMApiSvc }}
---
apiVersion: v1
kind: Service
metadata:
  name: nsmmgr
  namespace: nsm-system
  labels:
    app: nsmmgr
spec:
  ports:
    - port: 5000
      name: registry
    - port: {{ .Values.global.NSMApiSvcPort | default "5001" }}
      name: api
  type: {{ .Values.global.NSMApiSvcType | default "ClusterIP" }}
  selector:
    app: nsmmgr-daemonset
{{- end }}

