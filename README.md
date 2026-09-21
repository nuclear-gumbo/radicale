# radicale

Container image for [Radicale](https://radicale.org), built on alpine with
[s6-overlay](https://github.com/just-containers/s6-overlay). Published to
`ghcr.io/nuclear-gumbo/radicale`.

Upstream ships no image of its own, and this one is built to drop into a rootless
podman stack: s6 runs as container root, which under rootless podman *is* the
unprivileged host service account, so bind-mounted data stays owned by that user
with no PUID/PGID juggling.

## Contents

| Path | What |
| --- | --- |
| `Dockerfile` | alpine base, pinned s6-overlay (checksum verified), radicale in a venv |
| `rootfs/etc/s6-overlay/` | the single `radicale` longrun service |
| `rootfs/etc/radicale/config` | default config, override by mounting your own |
| `.github/workflows/build.yaml` | builds and pushes to ghcr on push to `main` |

`bcrypt` comes from alpine's `py3-bcrypt` and the venv is created with
`--system-site-packages`, so the build needs no compiler toolchain.

## Usage

```
podman run -d --name radicale -p 127.0.0.1:5232:5232 \
  -v ./data:/var/lib/radicale/collections \
  -v ./config:/etc/radicale/config:ro \
  -v ./users:/run/secrets/users:ro \
  ghcr.io/nuclear-gumbo/radicale:3.8.0
```

The image runs read-only if you set `S6_READ_ONLY_ROOT=1` and give it tmpfs on
`/run` and `/tmp`.

Create the htpasswd file with apache's `htpasswd`:

```
htpasswd -cBC 12 users <name>
```

Radicale reads the `$2y$` hashes it produces with `htpasswd_encryption = bcrypt`.

## Bumping Radicale

Edit `ARG RADICALE_VERSION` in the `Dockerfile` and push. The workflow reads that
arg for the image tag and prints the pushed digest in the run summary.
