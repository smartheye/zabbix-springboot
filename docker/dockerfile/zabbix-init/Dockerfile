# 基于轻量的 alpine 镜像构建
FROM alpine:latest

# 安装 curl 和 jq（alpine 官方源直接支持）
RUN apk add --no-cache curl jq

# 工作目录
WORKDIR /app

# 容器启动时执行的命令（后续通过 docker-compose 挂载脚本并覆盖）
CMD ["sh"]