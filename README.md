# radicale

Container image for [Radicale](https://radicale.org), the CalDAV and CardDAV
server. Built on alpine with [s6-overlay](https://github.com/just-containers/s6-overlay)
and published to `ghcr.io/nuclear-gumbo/radicale`.

## Why this and not the official image

Radicale publishes its own image at `ghcr.io/kozea/radicale`. If you want arm
support or a non-root container, use that one instead. It is the better default.

This image is built for rootless podman on amd64. It runs as container root,
which under rootless podman is the unprivileged host account that owns the bind
mounts, so data files stay owned by that user and there is no PUID/PGID juggling.
The official image runs as uid 1000, which gets remapped into the subuid range
and puts you back in ownership fixups.

Smaller differences:

- The base image, the s6-overlay tarballs and the Radicale version are pinned. The s6 tarballs are checksum verified.
- `bcrypt` comes from alpine's `py3-bcrypt` and the venv is created with `--system-site-packages`, so the build needs no gcc or rust toolchain. The official build compiles it.
- It ships a config that works. The official image has no `/etc/radicale` at all, so it starts with `auth type = denyall`.
- 89 MB against 107 MB.

What you give up: this image is amd64 only, and it has no `git`, `htpasswd`,
`curl` or `ssh` inside it. The official image has all of those, so Radicale's git
versioning hook works there and not here.

## Usage

```
podman run -d --name radicale -p 127.0.0.1:5232:5232 \
  -v ./data:/var/lib/radicale/collections \
  -v ./users:/etc/radicale/users:ro \
  ghcr.io/nuclear-gumbo/radicale:3.8.0
```

To use your own config, mount over the one in the image:

```
  -v ./config:/etc/radicale/config:ro
```

The image runs with a read-only root filesystem if you set `S6_READ_ONLY_ROOT=1`
and give it tmpfs on `/run` and `/tmp`.

## Users

There is no `htpasswd` in the image, so create the file on the host:

```
htpasswd -cBC 12 users <name>
```

The shipped config sets `htpasswd_encryption = autodetect`, which reads the `$2y$`
bcrypt hashes that command writes. Drop the `-c` to add more users to an existing
file.

## What's here

| Path | What |
| --- | --- |
| `Dockerfile` | alpine base, pinned s6-overlay, radicale in a venv |
| `rootfs/etc/s6-overlay/` | the single `radicale` longrun service |
| `rootfs/etc/radicale/config` | default config, override by mounting your own |
| `.github/workflows/build.yaml` | builds and pushes to ghcr on push to `main` |

## Bumping Radicale

Edit `ARG RADICALE_VERSION` in the `Dockerfile` and push. The workflow reads that
arg for the image tag and prints the pushed digest in the run summary.

## License

GPL-3.0-or-later, see [LICENSE](LICENSE). Radicale itself is GPL-3.0-or-later and
this image ships it, so the same terms carry over. s6-overlay is ISC, which the
GPL allows.
