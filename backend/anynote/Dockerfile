# 使用官方的 ASP.NET Core 运行时镜像作为基础镜像
FROM mcr.microsoft.com/dotnet/runtime-deps:8.0.8 AS base
WORKDIR /app

# 使用 ARG 来设置目标架构
ARG TARGETARCH

# 根据目标架构复制相应的文件
COPY ./out/linux-${TARGETARCH} .

# 创建 /data 目录
RUN mkdir /data

# 暴露应用程序端口
EXPOSE 8080

# 设置应用程序入口点
ENTRYPOINT ["./anynote"]