# Commands used in https://labs.play-with-k8s.com/
# kubeadm init --apiserver-advertise-address $(hostname -i)
#  mkdir -p $HOME/.kube
#  cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
#  chown $(id -u):$(id -g) $HOME/.kube/config
# kubectl apply -n kube-system -f \
#    "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 |tr -d '\n')"

SERVICE_ACCOUNT_NAME="myservice3"
USER_NAME="myservice3-user"
CONTEXT_NAME="myservice3-context"


if [ ! -d "~/tmp" ]; then
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
kubectl create -f ~/tmp/serviceaccount.yaml

# Role.yaml
echo "[*] Creating role"

cat > ~/tmp/Role.yaml <<EOF 
kind: Role
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata: 
  namespace: default
  name: my-role
rules: 
- apiGroups: ["", "extensions", "apps"]
  resources: ["pods"]
  verbs: ["get", "list"] 
EOF
kubectl create -f ~/tmp/Role.yaml

# RoleBinding.yaml
echo "[*] Creating role binding"

cat > ~/tmp/RoleBinding.yaml <<EOF  
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata: 
  name: my-role-binding
  namespace: default
subjects: 
- kind: ServiceAccount 
  name: $SERVICE_ACCOUNT_NAME
  namespace: default
  apiGroup: ""
roleRef: 
  kind: Role
  name: my-role
  apiGroup: ""
EOF
kubectl create -f ~/tmp/RoleBinding.yaml


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
curl -k -v -H "Authorization: Bearer $TOKEN" https://127.0.0.1:6443/api/v1/namespaces/default/pods
