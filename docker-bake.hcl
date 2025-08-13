group "all" {
    targets = [
        "dev-docs",
        "auth"
    ]
}


// We do not have a GCP Docker repo set up yet, so `docker push` won't work
// but we can still build the images locally
variable "BAKE_HOST" {
  default = "europe-west2-docker.pkg.dev"
}
variable "BAKE_PROJECT" {
  default = "cambridge-ifm"
}
variable "BAKE_REPO" {
  default = "dt-demo-gcp"
}
variable "BAKE_PREFIX" {
  default = "${BAKE_HOST}/${BAKE_PROJECT}/${BAKE_REPO}"
}


target "dev-docs" {
  context = "./dev-docs"
  dockerfile = "Dockerfile"
  tags = ["${BAKE_PREFIX}/dev-docs:latest"]
}

target "auth" {
  context = "."  # UV workspace root, not member root
  dockerfile = "dt-demo-gcp-auth/Dockerfile"
  tags = ["${BAKE_PREFIX}/auth:latest"]
}
