module "gke_addons" {
  source = "./modules/gke_addons"

  ci_service_account_email = module.ci_cd.ci_service_account_email
  app_namespace            = var.app_namespace
  cert_manager_version     = var.cert_manager_version
  flink_operator_version   = var.flink_operator_version

  depends_on = [module.gke]
}

moved {
  from = kubernetes_cluster_role_binding_v1.gha_cluster_admin
  to   = module.gke_addons.kubernetes_cluster_role_binding_v1.gha_cluster_admin
}

moved {
  from = kubernetes_namespace_v1.wikistream
  to   = module.gke_addons.kubernetes_namespace_v1.wikistream
}

moved {
  from = kubernetes_namespace_v1.cert_manager
  to   = module.gke_addons.kubernetes_namespace_v1.cert_manager
}

moved {
  from = helm_release.cert_manager
  to   = module.gke_addons.helm_release.cert_manager
}

moved {
  from = kubernetes_namespace_v1.flink_operator
  to   = module.gke_addons.kubernetes_namespace_v1.flink_operator
}

moved {
  from = helm_release.flink_operator
  to   = module.gke_addons.helm_release.flink_operator
}

moved {
  from = data.http.gcp_provider_yaml
  to   = module.gke_addons.data.http.gcp_provider_yaml
}

moved {
  from = helm_release.secrets_store_csi
  to   = module.gke_addons.helm_release.secrets_store_csi
}

moved {
  from = kubectl_manifest.secrets_store_gcp_provider
  to   = module.gke_addons.kubectl_manifest.secrets_store_gcp_provider
}
