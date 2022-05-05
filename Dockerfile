FROM gcr.io/kaniko-project/executor:v1.7.0-slim as executor

FROM alpine:3.15.4 as downloader
WORKDIR /root
RUN  wget https://github.com/google/go-containerregistry/releases/download/v0.8.0/go-containerregistry_Linux_x86_64.tar.gz \
    && tar -zxvf go-containerregistry_Linux_x86_64.tar.gz

FROM alpine:3.15.4
WORKDIR /workspace

COPY --from=executor /kaniko/executor /kaniko/executor
COPY --from=downloader /root/crane /kaniko/crane
COPY entrypoint.sh /kaniko/

RUN apk update && apk upgrade
