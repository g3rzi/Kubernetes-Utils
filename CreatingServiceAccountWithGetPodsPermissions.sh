# kubeadm init --apiserver-advertise-address $(hostname -i)
#  mkdir -p $HOME/.kube
#  cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
#  chown $(id -u):$(id -g) $HOME/.kube/config
# kubectl apply -n kube-system -f \
#    "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 |tr -d '\n')"

SERVICE_ACCOUNT_NAME="myservice3"
USER_NAME="myservice3-user"
CONTEXT_NAME="myservice3-context"
ROLE_NAME="my-role"
ROLE_BINDING_NAME="my-role-binding"

# Clean all
# kubectl delete serviceaccount $SERVICE_ACCOUNT_NAME
# kubectl delete role $ROLE_NAME
# kubectl delete rolebindings $ROLE_BINDING_NAME
# kubectl config delete-context $CONTEXT_NAME
# kubectl config unset "users.$USER_NAME"

if [ ! -d ~/tmp ]; then
	echo "[*] Creating ~/tmp folder"
	mkdir ~/tmp
fi

# ServiceAccount creation
echo "[*] Creating service account: $SERVICE_ACCOUNT_NAME"

cat > ~/tmp/serviceaccount.yaml <<EOF 
apiVersion: v1
kind: ServiceAccount
metadata:
  name: $SERVICE_ACCOUNT_NAME
EOF

IS_EXIST=`kubectl get serviceaccounts $SERVICE_ACCOUNT_NAME`
if [ "$IS_EXIST" == "" ]; then
	echo "[*] Wasn't exist... creating now..."
	kubectl create -f ~/tmp/serviceaccount.yaml

else
	echo "[*] ServiceAccount already exist, applying changes"
	kubectl apply -f ~/tmp/serviceaccount.yaml
fi

# Role.yaml
echo "[*] Creating role"

cat > ~/tmp/Role.yaml <<EOF 
kind: Role
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata: 
  namespace: default
  name: $ROLE_NAME
rules: 
- apiGroups: ["", "extensions", "apps"]
  resources: ["pods"]
  verbs: ["get", "list"] 
EOF

IS_EXIST=`kubectl get role $ROLE_NAME`
if [ "$IS_EXIST" == "" ]; then
	echo "[*] Wasn't exist... creating now..."
	kubectl create -f ~/tmp/Role.yaml

else
	echo "[*] Role already exist, applying changes"
	kubectl apply -f ~/tmp/Role.yaml
fi

# RoleBinding.yaml
echo "[*] Creating role binding"

cat > ~/tmp/RoleBinding.yaml <<EOF  
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata: 
  name: $ROLE_BINDING_NAME
  namespace: default
subjects: 
- kind: ServiceAccount 
  name: $SERVICE_ACCOUNT_NAME
  namespace: default
  apiGroup: ""
roleRef: 
  kind: Role
  name: $ROLE_NAME
  apiGroup: ""
EOF

IS_EXIST=`kubectl get rolebindings $ROLE_BINDING_NAME`
if [ "$IS_EXIST" == "" ]; then
	echo "[*] Wasn't exist... creating now..."
	kubectl create -f ~/tmp/RoleBinding.yaml

else
	echo "[*] RoleBinding already exist, applying changes"
	kubectl apply -f ~/tmp/RoleBinding.yaml
fi

SECRET_NAME=`kubectl get serviceaccounts $SERVICE_ACCOUNT_NAME -o json | jq -r '.secrets[].name'`
TOKEN=`kubectl get secrets $SECRET_NAME -o json | jq -r '.data | .token' | base64 -d`

# Create user with the JWT token of the service account
echo "[*] Setting credentials for user: $USER_NAME"
kubectl config set-credentials $USER_NAME --token=$TOKEN

echo "[*] Setting context: $CONTEXT_NAME"
kubectl config set-context $CONTEXT_NAME \
--cluster=kubernetes \
--namespace=default \
--user=$USER_NAME

echo "[*] Trying: \"kubectl get pods --context=$CONTEXT_NAME\""
kubectl get pods --context=$CONTEXT_NAME

echo "[*] Trying: \"curl -k -v -H \"Authorization: Bearer $TOKEN\" https://127.0.0.1:6443/api/v1/namespaces/default/pods\""
# https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.10/#list-62
curl -k -v -H "Authorization: Bearer $TOKEN" https://127.0.0.1:6443/api/v1/namespaces/default/pods
