// Input from .drone.yml
local IMAGENAME=std.extVar("input.IMAGENAME");
local VERSION=std.extVar("input.VERSION");
local cdPath=std.extVar("input.cdPath");


// 
local BRANCHNAME=std.extVar("build.branch");
// local BRANCHNAME="main";
local BRANCHNAMELIST={"main":"1","master":"2"};
// local ISBRANCHMAIN = [
//   { name: 'food_' + type, value: 'like' }
//   for type in food_type
// ];
// local ISBRANCHMAIN = std.objectHas(BRANCHNAME, "master");

local PROJECT_ID(BRANCH)=
if BRANCH == "develop" then "popoint-dev"
else if BRANCH == "staging" then "popoint-staging"
else if BRANCH in BRANCHNAMELIST then "popoint-production"
else "";

local KUSPATH(BRANCH)=
if BRANCH == "develop" then "dev"
else if BRANCH == "staging" then "staging"
else if BRANCH in BRANCHNAMELIST then "prod-oct25"
else "";



{ 
//   "ISBRANCHMAIN": ISBRANCHMAIN,
  "kind": "pipeline",
  "name": "pythonWithNginx-crane",
  "type": "kubernetes",
  "steps": [
    {
      "name": "Build and Push nginx image on "+BRANCHNAME,
      "image": "core-harbor.popoint.com.tw/library/drone-kaniko:v3.3",
      "environment": {
        "PKG_VERSION": VERSION,
        "BASE64_TOKEN": {
          "from_secret": "HARBOR_DRONE_BASE64_TOKEN"
        },
        "REGISTRY_USER": "rbc_robot$drone",
        "DOCKERFILE_PATH": "/drone/src/Dockerfile_nginx",
        "REGISTRY": "core-harbor.popoint.com.tw",
        "PROJECT_ID": PROJECT_ID(BRANCHNAME),
        "IMAGE_PATH": IMAGENAME+"-nginx"
      },
      "commands": [     
        "/kaniko/executor -f $DOCKERFILE_PATH -d \"$REGISTRY/$PROJECT_ID/$IMAGE_PATH:$PKG_VERSION-${DRONE_COMMIT_SHA:0:8}-${DRONE_BUILD_NUMBER}\"  -c dir://./ --no-push --tarPath image-nginx.tar",
        "echo \"$PKG_VERSION-${DRONE_COMMIT_SHA:0:8}-${DRONE_BUILD_NUMBER}\" > imagetag_nginx.txt",
        "/kaniko/entrypoint.sh",
        "/kaniko/crane push image-nginx.tar \"$REGISTRY/$PROJECT_ID/$IMAGE_PATH:$PKG_VERSION-${DRONE_COMMIT_SHA:0:8}-${DRONE_BUILD_NUMBER}\"",
        "rm -f image-nginx.tar",    
        "echo \"Succeed to push to Harbor $REGISTRY/$PROJECT_ID/$IMAGE_PATH:$PKG_VERSION-${DRONE_COMMIT_SHA:0:8}-${DRONE_BUILD_NUMBER}!!!\""
      ],
      "when": {
        "event": [
          "promote",
          "push"
        ]
      }
    },
    {
      "name": "Build and Push api image on "+BRANCHNAME,
      "image": "core-harbor.popoint.com.tw/library/drone-kaniko:v3.3",
      "environment": {
        "PKG_VERSION": VERSION,
        "BASE64_TOKEN": {
          "from_secret": "HARBOR_DRONE_BASE64_TOKEN"
        },
        "REGISTRY_USER": "rbc_robot$drone",
        "DOCKERFILE_PATH": "/drone/src/Dockerfile",
        "REGISTRY": "core-harbor.popoint.com.tw",
        "PROJECT_ID": PROJECT_ID(BRANCHNAME),
        "IMAGE_PATH": IMAGENAME
      },
      "commands": [
        "/kaniko/executor -f $DOCKERFILE_PATH --build-arg APP=$IMAGE_PATH --build-arg APP_VERSION=$PKG_VERSION -d \"$REGISTRY/$PROJECT_ID/$IMAGE_PATH:$PKG_VERSION-${DRONE_COMMIT_SHA:0:8}-${DRONE_BUILD_NUMBER}\"  -c dir://./ --no-push --tarPath image.tar",
        "echo \"$PKG_VERSION-${DRONE_COMMIT_SHA:0:8}-${DRONE_BUILD_NUMBER}\" > imagetag_api.txt",
        "/kaniko/entrypoint.sh",        
        "/kaniko/crane push image.tar \"$REGISTRY/$PROJECT_ID/$IMAGE_PATH:$PKG_VERSION-${DRONE_COMMIT_SHA:0:8}-${DRONE_BUILD_NUMBER}\"", 
        "rm -f image.tar",
        "echo \"Succeed to push to Harbor $REGISTRY/$PROJECT_ID/$IMAGE_PATH:$PKG_VERSION-${DRONE_COMMIT_SHA:0:8}-${DRONE_BUILD_NUMBER}!!!\""
      ],
      "when": {
        "event": [
          "promote",
          "push"
        ]
      }
    },
    {
      "name": "Path Iac yaml on "+BRANCHNAME,
      "image": "core-harbor.popoint.com.tw/library/git-kustomize:v1.0.0-a880ab88",
      "environment": {
        "SSH_KEY": {
          "from_secret": "SSH_KEY"
        },
        "MANIFEST_HOST": "gitea-ssh.gitea.svc",
        "MANIFEST_USER": "cd-repos",
        "MANIFEST_REPO": cdPath,
        "SSH_PORT": 2022,
        "KUSPATH": KUSPATH(BRANCHNAME),
        "IMAGES": "core-harbor.popoint.com.tw/"+PROJECT_ID(BRANCHNAME)+"/"+IMAGENAME+"-nginx"+",core-harbor.popoint.com.tw/"+PROJECT_ID(BRANCHNAME)+"/"+IMAGENAME
      },
      "commands": [
        "export IMAGE_TAG=`cat imagetag_nginx.txt`",
        "/bin/entrypoint.sh",
        "cat $MANIFEST_REPO/$KUSPATH/kustomization.yaml"
      ],
      "depends_on": [
          "Build and Push nginx image on "+BRANCHNAME,
          "Build and Push api image on "+BRANCHNAME
          ]
    },
    {
      "name": "Send telegram notification",
      "image": "appleboy/drone-telegram",
      "settings": {
        "token": {
          "from_secret": "bot-token"
        },
        "to": {
          "from_secret": "chatid"
        },
        "message": "{{#success build.status}}\n {{repo.name}} build {{build.number}} succeeded.\nCommit sha: {{commit.sha}}. Check from {{build.link}}. Good job. {{else}}\n  {{repo.name}} build {{build.number}} failed.\nCommit sha: {{commit.sha}}. Check from {{build.link}}. Fix it please. {{/success}}            \n"
      },
      "depends_on": ["Path Iac yaml on "+BRANCHNAME ],
      "when": {
        "status": [
          "success",
          "failure"
        ]
      }
    }
  ]
}