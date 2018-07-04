# The adapter name can different, like 'ens33' instead of 'eth0'
MASTER_SERVER_IP=`ip addr show eth0 | grep -Po 'inet \K[\d.]+'`
#MASTER_SERVER_IP="192.168.0.17"
MASTER_SERVER_PORT="6443"

CA_CRT_PATH="/etc/kubernetes/pki/ca.crt"
SHA=`openssl x509 -pubkey -in $CA_CRT_PATH | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //'`

# Might need `sudo`
TOKEN_LIST=`kubeadm token list` 

TOKEN=`echo $TOKEN_LIST | cut -d ' ' -f8`

echo "kubeadm join --token $TOKEN $MASTER_SERVER_IP:$MASTER_SERVER_PORT --discovery-token-ca-cert-hash sha256:$SHA"
