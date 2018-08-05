resource "kubernetes_namespace" "jx-production" {
  metadata {
    name = "jx-production"
    labels {
      env  = "production"
      team = "jx"
    }
  }
}

resource "kubernetes_namespace" "jx-staging" {
  metadata {
    name = "jx-staging"
    labels {
      env  = "staging"
      team = "jx"
    }
  }
}
