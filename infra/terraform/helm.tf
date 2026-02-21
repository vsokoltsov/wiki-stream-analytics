data "http" "gcp_provider_yaml" {
  url = "https://raw.githubusercontent.com/GoogleCloudPlatform/secrets-store-csi-driver-provider-gcp/v1.11.0/deploy/provider-gcp-plugin.yaml"
}

resource "helm_release" "secrets_store_csi" {
  count = 0
  name       = "csi-secrets-store"
  namespace  = "kube-system"
  repository = "https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts"
  chart      = "secrets-store-csi-driver"
  version    = "1.4.5"

  set  = [{
    name  = "syncSecret.enabled"
    value = "true"
  }, {
    name  = "enableSecretRotation"
    value = "true"
  }, {
    name  = "installCRDs"
    value = "true"
  }]
}

resource "kubectl_manifest" "secrets_store_gcp_provider" {
  count = 0
  yaml_body  = data.http.gcp_provider_yaml.response_body
  depends_on = [helm_release.secrets_store_csi]
}