docker run --user root  -v /Users/felix.hochleitner/GolandProjects/aws-nuke/config.yaml:/tmp/config.yaml quay.io/rebuy/aws-nuke:v2.22.1 --access-key-id=$ACCESS_KEY --secret-access-key=$SECRET_ACCESS_KEY --config /tmp/config.yaml --force --no-dry-run



apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: httpd-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
  - http:
      paths:
      - path: /demo
        pathType: Prefix
        backend:
          service:
            name: httpd
            port:
              number: 80