# This file configures ArgoCD to track your gitops-repo repository paths dynamically.

resource "time_sleep" "wait_for_argocd" {
    depends_on = [helm_release.argocd]
    create_duration = "30s"
}

resource "kubernetes_manifest" "argocd_application" {
    manifest = {
        apiVersion = "argoproj.io/v1alpha1"
        kind = "Application"
        metadata = {
            name = "my-app-gitops"
            namespace = "argocd"
        }
        spec = {
            project = "default"
            source = {
                repoURL        = "https://github.com/Akshatha-wq/gitops-repo.git" # Replace with your real repo URL
                targetRevision = "HEAD"
                path           = "charts/my-app"
            }
            destination = {
                server    = "https://kubernetes.default.svc"
                namespace = "production"
            }
            syncPolicy = {
                automated = {
                    prune = true
                    selfHeal = true  # Critical for enabling automated cluster self-healing features
                }
            syncOptions = [
                "CreateNamespace=true"
                ]          
            }
        }
    }
    depends_on = [time_sleep.wait_for_argocd]
}
