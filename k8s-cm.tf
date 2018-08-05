resource "kubernetes_config_map" "staging-player" {
  metadata {
    name      = "tf-cfg"
    namespace = "jx-staging"
  }

  data {
    ENV_NAME    = "staging"
    PLAYER_NAME = "Player42"
    COLOR       = "blue"
  }
}
resource "kubernetes_config_map" "production-player" {
  metadata {
    name      = "tf-cfg"
    namespace = "jx-production"
  }

  data {
    ENV_NAME    = "production"
    PLAYER_NAME = "Player1"
    COLOR       = "red"
  }
}
