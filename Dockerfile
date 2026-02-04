# Start with a rust alpine image
FROM rust:1-alpine3.19

# This is important, see https://github.com/rust-lang/docker-rust/issues/85
ENV RUSTFLAGS="-C target-feature=-crt-static"

# if needed, add additional dependencies here
RUN set -eux \
    && apk add --no-cache --no-scripts --virtual .build-deps \
    # 构建依赖
    musl-dev \
    git

# set the workdir and copy the source into it
WORKDIR /app
# COPY ./ /app

RUN set -eux \
    && git clone --depth 1 -b main https://github.com/bailangvvkruner/mini-docker-rust /app

# do a release build
RUN cargo build --release
RUN strip target/release/mini-docker-rust

# use a plain alpine image, the alpine version needs to match the builder
FROM alpine:3.19

# if needed, install additional dependencies here

RUN apk add --no-cache libgcc
# copy the binary into the final image

COPY --from=0 /app/target/release/mini-docker-rust .

# set the binary as entrypoint
ENTRYPOINT ["/mini-docker-rust"]