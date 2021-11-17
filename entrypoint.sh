#!/bin/sh


export REGISTRY_PASSWORD=$(echo -n "$BASE64_TOKEN" | base64 -d)
export BASE64_AUTH=$(echo -n "$REGISTRY_USER:$REGISTRY_PASSWORD" | base64)


cat << EOF > ~/.docker/config.json
{
	"auths": {
		"$REGISTRY": {
			"auth": "$BASE64_AUTH"
		}
	}
}
EOF