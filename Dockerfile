# Start with a rust alpine image
# FROM rust:1-alpine3.19
FROM rust:alpine AS builder

# This is important, see https://github.com/rust-lang/docker-rust/issues/85
# ENV RUSTFLAGS="-C target-feature=-crt-static"

WORKDIR /app

# if needed, add additional dependencies here
# RUN apk add --no-cache musl-dev
RUN set -eux \
    FILENAME=mini-docker-rust
    # && mkdir -p /app \
    && apk add --no-cache --no-scripts --virtual .build-deps \
    musl-dev \
    # libgcc \
    git \
    # 尝试安装 upx，如果不可用则继续（某些架构可能不支持）
    \
    && apk add --no-cache --no-scripts --virtual .upx-deps \
        upx 2>/dev/null || echo "upx not available, skipping compression" \
    \
    # set the workdir and copy the source into it
    # WORKDIR /app
    # COPY ./ /app
    && git clone --depth 1 -b main https://github.com/bailangvvkruner/mini-docker-rust . \
    \
    # do a release build
    # RUN cargo build --release
    # RUN strip target/release/mini-docker-rust
    && RUSTFLAGS="-C target-feature=-crt-static" cargo build --release \
    && strip target/release/$FILENAME \
    # && (upx --best --lzma mini-docker-rust 2>/dev/null || echo "upx compression skipped") \
    # 清理Go缓存和临时文件以释放空间
    && du -b $FILENAME


# use a plain alpine image, the alpine version needs to match the builder
# FROM alpine:3.19 AS final
FROM scratch AS final

# if needed, install additional dependencies here
# RUN apk add --no-cache libgcc
# RUN apk add --no-cache --no-scripts --virtual .build-deps \
#     libgcc

# 复制动态链接所需的库文件
# musl libc 加载器
# COPY --from=builder /lib/ld-musl-x86_64.so.1 /lib/
# GCC 运行时库
# COPY --from=builder /usr/lib/libgcc_s.so.1 /usr/lib/

# copy the binary into the final image
# COPY --from=0 /app/target/release/mini-docker-rust .
COPY --from=builder /app/target/release/mini-docker-rust .

# set the binary as entrypoint
ENTRYPOINT ["/mini-docker-rust"]