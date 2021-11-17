
# Usage
## For Drone CI

```
kind: pipeline
type: kubernetes
name: build

- name: Build and Push docker image
  image: dokfish/drone-kaniko:v1.1
  environment:
    TAG: v1.0-${DRONE_COMMIT_SHA:0:8}-${DRONE_BUILD_NUMBER}
    BASE64_TOKEN:
      from_secret: BASE64_TOKEN
    REGISTRY_USER: "robot$drone"
    DOCKERFILE_PATH: "/drone/src/Dockerfile"
    REGISTRY: "core-harbor.example.com"
    PROJECT_ID: "library"
    IMAGE_PATH: "example-app"
  commands:
  - /workspace/entrypoint.sh
  - /kaniko/executor -f $DOCKERFILE_PATH  -d "$REGISTRY/$PROJECT_ID/$IMAGE_PATH:$TAG"  -c dir://./ --cache
  ```

  The ``$BASE64_TOKEN`` has to be hashed by base64.  
  Set in Drone secret or orgsecret.
  ```
  echo -n "$PASSWORD" | base64
  ```
