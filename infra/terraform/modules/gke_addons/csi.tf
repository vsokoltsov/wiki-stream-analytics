data "http" "gcp_provider_yaml" {
  url = "https://raw.githubusercontent.com/GoogleCloudPlatform/secrets-store-csi-driver-provider-gcp/v1.11.0/deploy/provider-gcp-plugin.yaml"
}

resource "kubectl_manifest" "secrets_store_gcp_provider" {
  count      = 0
  yaml_body  = data.http.gcp_provider_yaml.response_body
  depends_on = [helm_release.secrets_store_csi]
}

