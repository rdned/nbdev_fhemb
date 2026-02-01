name: CI

on:
  push:
    branches: ["main", "master"]
  pull_request:

jobs:
  test:
    runs-on: scienziatiello

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Run CI tests inside container (Option 1)
        env:
          GITHUB_REPOSITORY: ${{ github.repository }}
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

          FHEMB_CI: ${{ secrets.FHEMB_CI }}
          FHEMB_SSH_KEY: ${{ secrets.FHEMB_SSH_KEY }}
          FHEMB_SSH_USER: ${{ secrets.FHEMB_SSH_USER }}
          FHEMB_SSH_HOST: ${{ vars.FHEMB_SSH_HOST }}

          FHEMB_DB_NAME: ${{ vars.FHEMB_DB_NAME }}
          FHEMB_DB_USER: ${{ vars.FHEMB_DB_USER }}
          FHEMB_DB_PASS: ${{ secrets.FHEMB_DB_PASS }}
          FHEMB_DB_HOST: ${{ vars.FHEMB_DB_HOST }}
          FHEMB_DB_PORT: ${{ vars.FHEMB_DB_PORT }}

          FHEMB_REMOTE_PORT: ${{ vars.FHEMB_REMOTE_PORT }}

          NODENAME: ${{ vars.NODENAME }}
          FHEMB_LOCALROOT: ${{ vars.FHEMB_LOCALROOT }}
          FHEMB_MOUNT: ${{ vars.FHEMB_MOUNT }}
          FHEMB_AUDIOFILES: ${{ vars.FHEMB_AUDIOFILES }}

        run: |
          docker run --rm \
            --network host \
            -e GITHUB_REPOSITORY \
            -e GITHUB_TOKEN \
            -e FHEMB_CI \
            -e FHEMB_SSH_KEY \
            -e FHEMB_SSH_USER \
            -e FHEMB_SSH_HOST \
            -e FHEMB_DB_NAME \
            -e FHEMB_DB_USER \
            -e FHEMB_DB_PASS \
            -e FHEMB_DB_HOST \
            -e FHEMB_DB_PORT \
            -e FHEMB_REMOTE_PORT \
            -e NODENAME \
            -e FHEMB_LOCALROOT \
            -e FHEMB_MOUNT \
            -e FHEMB_AUDIOFILES \
            -e HOME=/root \
            -v ${{ github.workspace }}:/workspace \
            -w /workspace \
            rdned/nbdev-fhemb:2.4.14.unified \
            bash test.sh

