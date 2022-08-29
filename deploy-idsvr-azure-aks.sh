#!/bin/bash
set -eo pipefail

display_help() {
    echo -e "Usage: $(basename "$0") [-h | --help] [-i | --install]  [-d | --delete]  \n" >&2
    echo "** DESCRIPTION **"
    echo -e "This script can be used to deploy Curity Identity Server in Azure kubernetes cluster. \n"
    echo -e "OPTIONS \n"
    echo " --help      shows this help message and exit                                                                 "
    echo " --install   creates a aks cluster & deploys curity identity server along with other components               "
    echo " --start     starts up the environment                                                                        "
    echo " --stop      shuts down the environment                                                                       "
    echo " --delete    deletes the aks k8s cluster & identity server deployment                                         "
}


greeting_message() {
  echo "|----------------------------------------------------------------------------|"
  echo "|  Azure Kubernetes Service based Curity Identity Server Installation           |"
  echo "|----------------------------------------------------------------------------|"
  echo "|  Following components are going to be installed :                          |"
  echo "|----------------------------------------------------------------------------|"
  echo "| [1] AZURE AKS KUBERNETES CLUSTER                                           |"
  echo "| [2] CURITY IDENTITY SERVER ADMIN NODE                                      |"
  echo "| [3] CURITY IDENTITY SERVER RUNTIME NODE                                    |"
  echo "| [4] NGINX INGRESS CONTROLLER                                               |"
  echo "| [6] NGINX PHANTOM TOKEN PLUGIN                                             |"
  echo "| [7] EXAMPLE NODEJS API                                                     |"
  echo "|----------------------------------------------------------------------------|" 
  echo -e "\n"
}


pre_requisites_check() {
  # Check if azure cli, kubectl, helm & jq are installed
  if ! [[ $(az version) && $(helm version) && $(jq --version) ]]; then
      echo "Please install azure cli, kubectl, helm & jq to continue with the deployment .."
      exit 1 
  fi

  # Check for license file
  if [ ! -f 'idsvr-config/license.json' ]; then
    echo "Please copy a license.json file in the idsvr-config directory to continue with the deployment. License could be downloaded from https://developer.curity.io/"
    exit 1
  fi

  # To avoid accidental commit of sensitive data to repositories
  cp ./hooks/pre-commit ./.git/hooks

  echo -e "\n"
}


read_cluster_config_file() {
  echo "Reading the configuration from cluster-config/aks-cluster-config.json .."
  while read -r NAME; read -r VALUE; do
    if [ -z "$NAME" ]; then break; fi

  export "$NAME"="$VALUE" 

  done <<< "$(jq -rc '.[] | .[] | "\(.Name)\n\(.Value)"' "cluster-config/aks-cluster-config.json")"
}


create_aks_cluster() {
  read -p "Do you want to create a new aks cluster for deploying Curity Identity server ? [Y/y N/n] :" -n 1 -r
  echo -e "\n"

  if [[ $REPLY =~ ^[Yy]$ ]]
  then
    generate_self_signed_certificates
    echo -e "Creating AKS cluster for deployment..., this will take ~15mins.."
    az aks create -g $resource_group -n $cluster_name --kubernetes-version $cluster_version --node-osdisk-size $disk_size --node-vm-size $node_vm_size --node-count $node_count --enable-managed-identity --zones $availability_zones --enable-cluster-autoscaler --min-count $cluster_autoscaler_min_size --max-count $cluster_autoscaler_max_size
   
    # Set kubernetes context
    az aks get-credentials -g $resource_group -n $cluster_name 

  else
    echo "Not creating a new k8s cluster, assuming that an existing cluster is already available for deployment ..."
    generate_self_signed_certificates
  fi
 
  echo -e "\n"
}

is_pki_already_available() {
  echo -e "Verifying whether the certificates are already available .."
  if [[ -f certs/example.aks.ssl.key && -f certs/example.aks.ssl.pem ]] ; then
    echo -e "example.aks.ssl.key & example.aks.ssl.pem certificates already exist.., skipping regeneration of certificates\n"
    true
  else
    echo -e "Generating example.aks.ssl.key,example.aks.ssl.pem certificates using local domain names from cluster-config/aks-cluster-config.json..\n"
    false
  fi
}


generate_self_signed_certificates() { 
  if ! is_pki_already_available ; then
      bash ./create-self-signed-certs.sh
    echo -e "\n"
  fi
}


deploy_ingress_controller() {
  echo -e "Deploying Nginx ingress controller & adding phantom token plugin in the k8s cluster ...\n"
  
  # create secrets for TLS termination
  kubectl create secret tls example-aks-tls --cert=certs/example.aks.ssl.pem --key=certs/example.aks.ssl.key -n "$idsvr_namespace" || true
   
  envsubst < ingress-nginx-config/helm-values.yaml.template > ingress-nginx-config/helm-values.yaml

  # Deploy nginx ingress controller  
  helm upgrade --install ingress-nginx ingress-nginx \
    --repo https://kubernetes.github.io/ingress-nginx \
    --values ingress-nginx-config/helm-values.yaml \
    --namespace ingress-nginx --create-namespace
  echo -e "\n"
}


deploy_idsvr() {
  echo "Fetching Curity Idsvr helm chart ..."
  helm repo add curity https://curityio.github.io/idsvr-helm || true
  helm repo update

  envsubst < idsvr-config/helm-values.yaml.template > idsvr-config/helm-values.yaml

  echo -e "Deploying Curity Identity Server in the k8s cluster ...\n"
  helm install curity curity/idsvr --values idsvr-config/helm-values.yaml --namespace "${idsvr_namespace}" --create-namespace

  kubectl create secret generic idsvr-config --from-file=idsvr-config/idsvr-cluster-config.xml --from-file=idsvr-config/license.json -n "${idsvr_namespace}" || true

  # Copy the deployed artifacts to idsvr-config/template directory for reviewing 
  mkdir -p idsvr-config/templates
  helm template curity curity/idsvr --values idsvr-config/helm-values.yaml > idsvr-config/templates/deployed-idsvr-helm.yaml
  echo -e "\n"
}


deploy_simple_echo_api() {
  echo -e "Deploying simple echo api in the k8s cluster ...\n"
  kubectl create namespace "$api_namespace" || true

 # create secrets for TLS termination at ingress layer
  kubectl create secret tls example-aks-tls --cert=certs/example.aks.ssl.pem --key=certs/example.aks.ssl.key  -n "$api_namespace"

  kubectl apply -f simple-echo-api-config/echo-api-ingress-nginx.yaml -n "${api_namespace}"
  kubectl apply -f simple-echo-api-config/simple-echo-api-k8s-deployment.yaml -n "${api_namespace}"
  
  echo -e "\n"
}


startup_environment() {
  echo "Starting up the environment .."
  az aks start --name $cluster_name --resource-group $resource_group
}


shutdown_environment() {
  echo "Shutting down the environment .."
  az aks stop --name $cluster_name --resource-group $resource_group
}


tear_down_environment() {
  read -p "Identity server deployment and k8s cluster would be deleted, Are you sure? [Y/y N/n] :" -n 1 -r
  echo -e "\n"

  if [[ $REPLY =~ ^[Yy]$ ]]
  then
    helm uninstall curity -n "${idsvr_namespace}" || true
    helm uninstall ingress-nginx -n ingress-nginx || true
    kubectl delete -f simple-echo-api-config/simple-echo-api-k8s-deployment.yaml -n "${api_namespace}" || true
    az aks delete --name $cluster_name --resource-group $resource_group --no-wait --yes || true
    echo -e "\n" 
  else
    echo "Aborting the operation .."
    exit 1
  fi
}


environment_info() {
  echo "Waiting for LoadBalancer's External IP, sleeping for 60 seconds ..."
  sleep 60
  
  LB_IP=$(kubectl -n ingress-nginx get svc ingress-nginx-controller -o jsonpath="{.status.loadBalancer.ingress[0].ip}") || true  

  if [ -z "$LB_IP" ]; then LB_IP="<LoadBalancer-IP>"; fi
  
  echo -e "\n"
  
  echo "|--------------------------------------------------------------------------------------------------------------------------------------------------|"
  echo "|                                Environment URLS & Endpoints                                                                                      |"
  echo "|--------------------------------------------------------------------------------------------------------------------------------------------------|"
  echo "|                                                                                                                                                  |"
  echo "| [ADMIN UI]        https://admin.example.aks/admin                                                                                                |"
  echo "| [OIDC METADATA]   https://login.example.aks/~/.well-known/openid-configuration                                                                   |"
  echo "| [SIMPLE ECHO API] https://api.example.aks/echo                                                                                                   |"                                                                                                  
  echo "|                                                                                                                                                  |"
  echo "|                                                                                                                                                  |"
  echo "| * Curity administrator username is : admin and password is : $idsvr_admin_password                                                                "
  echo "| * Remember to add certs/example.aks.ca.pem to operating system's certificate trust store &                                                       |"
  echo "|   $LB_IP  admin.example.aks login.example.aks api.example.aks entry to /etc/hosts                                                                 "
  echo "|--------------------------------------------------------------------------------------------------------------------------------------------------|" 
}



# ==========
# entrypoint
# ==========

case $1 in
  -i | --install)
    greeting_message
    pre_requisites_check
    read_cluster_config_file
    create_aks_cluster
    deploy_idsvr
    deploy_simple_echo_api
    deploy_ingress_controller
    environment_info
    ;;
  -d | --delete)
    read_cluster_config_file
    tear_down_environment
    ;;
  --start)
    read_cluster_config_file
    startup_environment
    ;;
  --stop)
    read_cluster_config_file
    shutdown_environment
    ;;
  -h | --help)
    display_help
    ;;
  *)
    echo "[ERROR] Unsupported options"
    display_help
    exit 1
    ;;
esac