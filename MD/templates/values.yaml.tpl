installCRDs: false

server:
  extraArgs:
    - --insecure
  ingress:
    enabled: ${ argocd_ingress_enabled }
    annotations:
      kubernetes.io/ingress.class: ${ argocd_ingress_class }
      kubernetes.io/tls-acme: "${ argocd_ingress_tls_acme_enabled }"
      cert-manager.io/cluster-issuer: "letsencrypt-staging"
      alb.ingress.kubernetes.io/load-balancer-name: ${ argocd_load_balancer_name }
      alb.ingress.kubernetes.io/scheme: "internet-facing"
      alb.ingress.kubernetes.io/backend-protocol: HTTP
      alb.ingress.kubernetes.io/healthcheck-path: "/"
      external-dns.alpha.kubernetes.io/hostname: ${ argocd_server_host }
      external-dns.alpha.kubernetes.io/alias: "true"
      alb.ingress.kubernetes.io/listen-ports: [{"HTTP": 80}, {"HTTPS":443}]
      alb.ingress.kubernetes.io/listen-ports: '[{"HTTP":80},{"HTTPS":443}]'
      alb.ingress.kubernetes.io/ssl-redirect: "443"
    hosts:
      - ${ argocd_server_host }
    tls:
      - secretName: argocd-secret
        hosts:
          - ${ argocd_server_host }

  config:
    url: https://${ argocd_server_host }
    admin.enabled: "true"
    dex.config: |

  rbacConfig:
    policy.csv: |

    scopes: ""
    policy.matchMode: ""
