
group "default" {
  targets = ["base-gui"]
}

variable "TAG" {
  default = "dev"
}

target "novnc" {
  args = {
    VERSION = "v1.6.0"
  }

  dockerfile = "./dependencies/novnc.Dockerfile"
}

target "websockify" {
  args = {
    VERSION = "v0.13.0"
  }

  dockerfile = "./dependencies/websockify.Dockerfile"
}


target "base-gui" {
  name = "base-gui-${base}"

  args = {
    OS = "debian:${base}"
  }

  matrix = {
    base = ["bookworm", "bookworm-slim", "trixie", "trixie-slim"]
  }

  platforms = ["linux/amd64", "linux/arm64"]

  contexts = {
    novnc = "target:novnc"
    websockify = "target:websockify"
  }

  tags = [
    "max06net/base-gui:${TAG}-${base}"
  ]

  output = ["type=cacheonly"]
}

target "dev" {
  inherits  = ["base-gui-trixie-slim"]
  platforms = ["linux/amd64"]
  tags      = ["local/base-gui:dev"]
  output    = ["type=docker"]
}
