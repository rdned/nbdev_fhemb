# Build & CI Infrastructure

The CI/CD workflows are based on a docker container defined in `Dockerfile` that receives as its entrypoint

- `.github/workflows/test.yaml` or
- `.github/workflows/deploy.yaml`,

which in turn

1. use docker build scripts and
2. consume CI dependency pins via a reusable workflow job (`pins`).

## Docker Image

Any modification of the `Dockerfile` or any of the docker build scripts requires rebuilding docker image and publishing it:

```bash
# Build a docker image from the Dockerfile in the current directory
# and tag the resulting image as <image-name>:<image-tag>
docker build -t <image-name>:<image-tag> .

# Push the tagged image to the configured container registry.
# The image name must include the registry prefix unless Docker Hub is implied.
docker push <image-name>:<image-tag>
```

### Publishing Docker Images to a Registry

To make a Docker image pullable by CI/CD, it must be published to a container registry.
Docker Desktop’s *My Hub* is only a UI for your **Docker Hub** account, and it does not authenticate you to any other registry — each registry requires its own explicit `docker login`. Images without a registry prefix (e.g., `myapp:1.0`) are pushed to **Docker Hub**.

> **Recommended image naming scheme**
>
> To ensure consistent builds and predictable CI behavior, use fully qualified image names with the following structure:
>
>`<image-name> = <registry>/<org-or-user>/<repo>-ci`
>
>where:
>
>- `<registry>` is the container registry host, for example,
>   - `docker.io` (default Docker Hub Registry),
>   - `ghcr.io` (GitHub Container Registry),
>   - `registry.gitlab.com` (GitLab Container Registry),
>   - `<aws-account>.dkr.ecr.<region>.amazonaws.com` (Amazon ECR),
>   - `<region>-docker.pkg.dev` (Google Artifact Registry),
>   - `registry.example.com` (Private/self‑hosted registries),
>- `<org-or-user>` is the GitHub namespace,
>- `<repo>-ci` is the repository name with a `-ci` suffix to distinguish CI images from runtime images.

`<image-tag>` are typically date, commit SHA, or semantic version.

Images for other than Docker Hub registries must use fully qualified names (e.g., `<registry>/<user>/<image>:<image-tag>`) and require explicit authentication, for example:

```bash
echo "$GHCR_PAT" | docker login ghcr.io -u <github-username> --password-stdin
```

## Docker build scripts

All Docker-related scripts now live under the `docker/` directory:

```text
docker/
  build.sh
  ci-prepare.sh
  configure-ssh.sh
  install-fhemb.sh
  setup-env.sh
  test.sh
```

The Dockerfile expects these paths, so keep all build scripts inside this directory.

## CI dependency pins

External CI dependencies are pinned explicitly in `.github/workflows/reusable-pins.yml`:

- **FHEMB_TAG** — version/tag of the external `fhemb` wheel.
- **CI_UTILS_COMMIT** — pinned commit of external CI helper scripts.
- **NBDEV_FHEMB_IMAGE** — pinned Docker image tag used to run CI build/test jobs.

To bump external dependencies, update only `.github/workflows/reusable-pins.yml` and open a PR.
