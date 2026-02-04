# Start with a rust alpine image
# FROM rust:1-alpine3.19
FROM rust:alpine

# This is important, see https://github.com/rust-lang/docker-rust/issues/85
ENV RUSTFLAGS="-C target-feature=-crt-static"

# if needed, add additional dependencies here
RUN set -eux && \
    cd /tmp && \
    apk add --no-cache --no-scripts --virtual .build-deps \
    # 构建依赖
    musl-dev \
    git && \
    git clone --depth 1 -b main https://github.com/bailangvvkruner/mini-docker-rust /app && \
    cargo build --release && \
    strip target/release/mini-docker-rust

# use a plain alpine image, the alpine version needs to match the builder
# FROM alpine:3.19
FROM alpine:latest

# if needed, install additional dependencies here

RUN apk add --no-cache libgcc
# copy the binary into the final image

COPY --from=0 /tmp/target/release/mini-docker-rust .

# set the binary as entrypoint
ENTRYPOINT ["/mini-docker-rust"]