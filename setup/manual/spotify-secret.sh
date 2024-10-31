#!/bin/bash

kubectl apply -f  ../../.creds/spotify-secret.yaml
PROXY_URL="spotify.jukebox.fhochleitner.dev"


echo "apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt
  name: spotify-auth-proxy
  namespace: spotify
spec:
  ingressClassName: nginx
  rules:
    - host: ${PROXY_URL}
      http:
        paths:
          - backend:
              service:
                name: spotify-auth-proxy
                port:
                  number: 27228
            path: /
            pathType: Prefix
  tls:
    - hosts:
        - ${PROXY_URL}
      secretName: spotify-fhochleitner-dev-tls
" | kubectl apply -f -

# kubectl apply -f ../../.creds/spotify-auth-proxy-config.yaml

echo "apiVersion: spotify.crossplane.io/v1beta1
kind: ProviderConfig
metadata:
  name: default
spec:
  credentials:
    secretRef:
      key: spotify-credentials
      name: provider-spotify-credentials
      namespace: crossplane-system
    source: Secret
" | kubectl apply -f -

kubectl create secret generic provider-spotify-credentials --from-file ../../.creds/spotify-credentials -n crossplane-system


## Secret and credential Formats:

#```yaml
#  apiVersion: v1
#  stringData:
#    SPOTIFY_PROXY_BASE_URL: "https://spotify.jukebox.fhochleitner.dev"
#    spotifyClientID: "your-client-id"
#    spotifyClientSecret: "your-client-secret"
#    spotifyProxyAPIKey: "your-api-key"
#  kind: Secret
#  metadata:
#    creationTimestamp: null
#    name: spotify-auth-proxy-config
#    namespace: spotify
#```

#{
#  "api_key": "api-key",
#  "auth_server": "spotify-auth-proxy-url"
#}