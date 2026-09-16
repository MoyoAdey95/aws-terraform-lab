# Built and run on ARM64. Fargate runs this task on Graviton, so the image
# built natively on an Apple Silicon Mac is the one that ships, with no
# cross-compilation. See runtime_platform in the ECS task definition.

# build stage: install deps into an isolated prefix
FROM python:3.12-slim AS builder

WORKDIR /build
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# runtime stage: copy only what we need
FROM python:3.12-slim

# The first ECR scan of this image found 6 critical and 12 high CVEs, all in
# Debian packages that ship with the base image (perl, glibc, sqlite3, pcre2,
# zlib) and none in the app or its Python dependencies. Debian had already
# published fixes for most of them, but the upstream python image had not
# been rebuilt to include them. Upgrading here pulls those fixes in at build
# time. The trade-off is that two builds on different days can differ, so the
# scan result is checked on every push rather than assumed.
RUN apt-get update \
    && apt-get upgrade -y \
    && rm -rf /var/lib/apt/lists/*

RUN useradd --create-home --uid 1001 appuser

WORKDIR /app
COPY --from=builder /install /usr/local

# COPY keeps the file mode from the build host and makes root the owner. A
# source file with mode 600 would be unreadable by appuser, which is what
# happened in k8s-observability-lab. --chown makes appuser the owner.
COPY --chown=appuser:appuser main.py .

USER appuser

ENV PORT=8080
CMD ["sh", "-c", "uvicorn main:app --host 0.0.0.0 --port ${PORT}"]
