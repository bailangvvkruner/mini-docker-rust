# Start with a rust alpine image
# FROM rust:1-alpine3.19
FROM rust:alpine
# FROM clux/muslrust:stable AS builder

# This is important, see https://github.com/rust-lang/docker-rust/issues/85
ENV RUSTFLAGS="-C target-feature=-crt-static"

# if needed, add additional dependencies here
RUN set -eux && \
    cd /tmp && \
    apk add --no-cache --no-scripts --virtual .build-deps \
    # 构建依赖
    musl-dev \
    git \
    && \
    # 尝试安装 upx，如果不可用则继续（某些架构可能不支持）
    apk add --no-cache --no-scripts --virtual .upx-deps \
        upx 2>/dev/null || echo "upx not available, skipping compression" \
    \
    && \
    git clone --depth 1 -b main https://github.com/bailangvvkruner/mini-docker-rust . && \
    cargo build --release && \
    strip target/release/mini-docker-rust && \
    # strip target/x86_64-unknown-linux-musl/release/mini-docker-rust && \
    # 尝试压缩二进制文件（如果 upx 可用）
    upx --best --lzma target/release/mini-docker-rust 2>/dev/null || echo "upx not available, skipping compression"
    # upx --best --lzma2 target/x86_64-unknown-linux-musl/release/mini-docker-rust 2>/dev/null || echo "upx not available, skipping compression"

# use a plain alpine image, the alpine version needs to match the builder
# FROM alpine:3.19
# FROM alpine:latest
# FROM scratch
FROM busybox:musl

# if needed, install additional dependencies here
RUN set -eux \
    && \
    apk add --no-cache --no-scripts --virtual .run-deps \
    libgcc

# copy the binary into the final image
COPY --from=0 /tmp/target/release/mini-docker-rust .
# COPY --from=builder /tmp/target/x86_64-unknown-linux-musl/release/mini-docker-rust /mini-docker-rust

# set the binary as entrypoint
ENTRYPOINT ["/mini-docker-rust"]