# SERVICE_ACCOUNT_NAME="myservice"
# Getting input from user
SERVICE_ACCOUNT_NAME="$1"

SERVICE_ACCOUNT_SECRET_NAME=`kubectl get serviceaccount $SERVICE_ACCOUNT_NAME -o json | jq -r '.secrets[].name'`

kubectl get secrets $SERVICE_ACCOUNT_SECRET_NAME -o json | jq -r '.data.token' | base64 -d
