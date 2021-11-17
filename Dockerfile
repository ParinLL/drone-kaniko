FROM gcr.io/kaniko-project/executor:v1.7.0-slim as executor

FROM alpine:3.14
WORKDIR /workspace

COPY --from=executor /kaniko /kaniko
COPY entrypoint.sh .

RUN apk update && apk upgrade && apk add jq && mkdir ~/.docker
# ENTRYPOINT [ "/kaniko/entrypoint.sh" ]
