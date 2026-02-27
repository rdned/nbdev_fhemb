# Build & CI Infrastructure

The CI/CD workflows

- `.github/workflows/test.yaml` or
- `.github/workflows/deploy.yaml`,

1. pulls the *Docker image* that defines the CI execution environment,
2. imports pinned CI dependencies through the reusable `pins` workflow job,
3. invokes the shared Docker build scripts within that environment, and
4. executes its *job steps* inside a container instantiated from that image.

## Docker Image

A Docker image is build from `Dockerfile`.

```bash
# Build a docker image from the Dockerfile in the current directory
# and tag the resulting image as <image-name>:<image-tag>
docker build \
  -t <image-name>:<image-tag> .

# Push the tagged image to the configured container registry.
# The image name must include the registry prefix unless Docker Hub is implied.
docker push <image-name>:<image-tag>
```

>**Publishing Docker Images to a Registry**
>
>To make a Docker image pullable by CI/CD, it must be published to a container registry.
>Docker Desktop’s *My Hub* is only a UI for your **Docker Hub** account, and it does not authenticate you to any other registry — each registry requires its own explicit `docker login`. Images without a registry prefix (e.g., `myapp:1.0`) are pushed to **Docker Hub**.
>
>>**Recommended image naming scheme**
>>
>>To ensure consistent builds and predictable CI behavior,
>>
>>1. use fully qualified image names with the following structure: `<image-name> = <registry>/<org-or-user>/<repo>-ci`
>>where:
>>    - `<registry>` is the container registry host, for example,
>>      - `docker.io` (default Docker Hub Registry),
>>      - `ghcr.io` (GitHub Container Registry),
>>      - `registry.gitlab.com` (GitLab Container Registry),
>>      - `<aws-account>.dkr.ecr.<region>.amazonaws.com` (Amazon ECR),
>>      - `<region>-docker.pkg.dev` (Google Artifact Registry),
>>      - `registry.example.com` (Private/self‑hosted registries),
>>    - `<org-or-user>` is the GitHub namespace,
>>    - `<repo>-ci` is the repository name with a `-ci` suffix to distinguish CI images from runtime images.
>>
>>2. `<image-tag> = <fhemb-version>-<nbdev-version>-<package-version>`

**Example Image**:

```text
rdned/nbdev_fhemb-ci:v0.2.2-3.0.12-0
```

where `docker.io` is implicit, i.e., this Docker image is published to Docker Hub.

Images for other than Docker Hub registries must use fully qualified names
and require explicit authentication, for example:

```bash
echo "$GHCR_PAT" | docker login ghcr.io -u <github-username> --password-stdin
```

## CI dependency pins

External CI dependencies are pinned explicitly in `.github/workflows/reusable-pins.yml`:

- **FHEMB_TAG** — version/tag of the external `fhemb` wheel. It is equal to `v<fhemb_version>`.

- **CI_UTILS_COMMIT** — pinned commit of external CI helper scripts.

- **NBDEV_VERSION** — pinned `nbdev` version used when building the CI container image.

- **NBDEV_FHEMB_IMAGE** — pinned Docker image tag used to run CI build/test jobs. It coincides with the `<image-tag>`.

When rebuilding the CI image, `Dockerfile` reads the pin automatically from `.github/workflows/reusable-pins.yml`:

```bash
docker build -t <image-name>:<image-tag> .
```

To bump external dependencies, update only `.github/workflows/reusable-pins.yml` and open a PR.

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

----

>Any modification of the `Dockerfile` or any of the docker build scripts requires rebuilding docker image and publishing it.
