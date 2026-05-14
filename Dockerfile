FROM debian:bookworm-slim

ARG TARGETARCH

COPY binaries/${TARGETARCH}/aptos /usr/local/bin/aptos

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && aptos --version

ENTRYPOINT ["aptos"]
