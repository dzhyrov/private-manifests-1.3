#!/bin/sh
set -e

DISABLE_ISTIO=${DISABLE_ISTIO:-false}

KF_JOBS_NS=kubeflow-jobs
RETRY_TIMEOUT=8
MANIFESTS_DIR=../private-manifests

test_env_vars()
{
    local ret_val=0

    # ????????
    
    # if [ ${DISABLE_NOTEBOOKSERVERS_LINK} != true -a ${DISABLE_NOTEBOOKSERVERS_LINK} != false ]; then
    #   echo 'DISABLE_NOTEBOOKSERVERS_LINK should be unset or set to either "true" or "false".'
    #   ret_val=1
    # fi

    # if [ ${DISABLE_KIALI_AND_GRAFANA} != true -a ${DISABLE_KIALI_AND_GRAFANA} != false ]; then
    #   echo 'DISABLE_KIALI_AND_GRAFANA should be unset or set to either "true" or "false".'
    #   ret_val=1
    # fi

    if [ ${DISABLE_ISTIO} != true -a ${DISABLE_ISTIO} != false ]; then
        echo 'DISABLE_ISTIO should be unset or set to either "true" or "false".'
        ret_val=1
    fi

    return $ret_val
}

delete_cert_manager()
{
    kubectl delete -k ${MANIFESTS_DIR}/common/cert-manager/cert-manager/overlays/self-signed
    kubectl delete -k ${MANIFESTS_DIR}/common/cert-manager/cert-manager-crds/base
    kubectl delete -k ${MANIFESTS_DIR}/common/cert-manager/cert-manager-kube-system-resources/base
}

delete_istio()
{
    kubectl delete -k ${MANIFESTS_DIR}/common/istio-1-9-0/istio-install/base
    kubectl delete -k ${MANIFESTS_DIR}/common/istio-1-9-0/istio-namespace/base
    kubectl delete -k ${MANIFESTS_DIR}/common/istio-1-9-0/istio-crds/base
}

delete_authservices()
{
    kubectl delete -k ${MANIFESTS_DIR}/common/oidc-authservice/base
    kubectl delete -k ${MANIFESTS_DIR}/common/dex/overlays/istio
}

delete_knative()
{
    kubectl delete -k ${MANIFESTS_DIR}/common/knative/knative-serving-crds/base
    kubectl delete -k ${MANIFESTS_DIR}/common/knative/knative-serving-install/base
    kubectl delete -k ${MANIFESTS_DIR}/common/knative/knative-eventing-crds/base
    kubectl delete -k ${MANIFESTS_DIR}/common/knative/knative-eventing-install/base
}

delete_cluster_local_gateway()
{
    kubectl delete -k ${MANIFESTS_DIR}/common/istio-1-9-0/cluster-local-gateway/base
}

delete_kf_services()
{
    kubectl delete -k ${MANIFESTS_DIR}/common/user-namespace/base
    kubectl delete -k ${MANIFESTS_DIR}/apps/xgboost-job/upstream/overlays/kubeflow
    kubectl delete -k ${MANIFESTS_DIR}/apps/mxnet-job/upstream/overlays/kubeflow
    kubectl delete -k ${MANIFESTS_DIR}/apps/mpi-job/upstream/overlays/kubeflow
    kubectl delete -k ${MANIFESTS_DIR}/apps/pytorch-job/upstream/overlays/kubeflow
    kubectl delete -k ${MANIFESTS_DIR}/apps/tf-training/upstream/overlays/kubeflow
    kubectl delete -k ${MANIFESTS_DIR}/apps/tensorboard/tensorboards-web-app/upstream/overlays/istio
    kubectl delete -k ${MANIFESTS_DIR}/apps/tensorboard/tensorboard-controller/upstream/overlays/kubeflow
    kubectl delete -k ${MANIFESTS_DIR}/apps/volumes-web-app/upstream/overlays/istio
    kubectl delete -k ${MANIFESTS_DIR}/apps/profiles/upstream/overlays/kubeflow
    kubectl delete -k ${MANIFESTS_DIR}/apps/jupyter/notebook-controller/upstream/overlays/kubeflow
    kubectl delete -k ${MANIFESTS_DIR}/apps/jupyter/jupyter-web-app/upstream/overlays/istio
    kubectl delete -k ${MANIFESTS_DIR}/apps/admission-webhook/upstream/overlays/cert-manager
    kubectl delete -k ${MANIFESTS_DIR}/apps/centraldashboard/upstream/overlays/istio
    kubectl delete -k ${MANIFESTS_DIR}/apps/katib/upstream/installs/katib-with-kubeflow
    kubectl delete -k ${MANIFESTS_DIR}/apps/kfserving/upstream/overlays/kubeflow
    kubectl delete -k ${MANIFESTS_DIR}/apps/pipeline/upstream/env/platform-agnostic-multi-user
    kubectl delete -k ${MANIFESTS_DIR}/common/istio-1-9-0/kubeflow-istio-resources/base
    kubectl delete -k ${MANIFESTS_DIR}/common/kubeflow-roles/base
    kubectl delete -k ${MANIFESTS_DIR}/common/kubeflow-namespace/base
}

install()
{    
    printf "\nTrying to delete kubeflow services...\n\n"
    while delete_kf_services; do printf "\n*** Retrying to delete kubeflow services... ***\n\n"; sleep ${RETRY_TIMEOUT}; done

    printf "\nTrying to delete cluster local gateway...\n\n"
    while delete_cluster_local_gateway; do printf "\n*** Retrying to delete cluster local gateway... ***\n\n"; sleep ${RETRY_TIMEOUT}; done
    
    printf "\nTrying to delete knative...\n\n"
    while delete_knative; do printf "\n*** Retrying to delete knative... ***\n\n"; sleep ${RETRY_TIMEOUT}; done

    printf "\nTrying to delete authservices...\n\n"
    while delete_authservices; do printf "\n*** Retrying to delete authservices... ***\n\n"; sleep ${RETRY_TIMEOUT}; done

    printf "\nTrying to delete istio...\n\n"
    while delete_istio; do printf "\n*** Retrying to delete istio... ***\n\n"; sleep ${RETRY_TIMEOUT}; done

    printf "\nTrying to delete cert manager...\n\n"
    while delete_cert_manager; do printf "\n*** Retrying to delete cert manager... ***\n\n"; sleep ${RETRY_TIMEOUT}; done
}


if test_env_vars; then
    # kubectl create ns ${KF_JOBS_NS}
    # kubectl delete -f ips.yaml
    # kubectl delete -k ./components/dex-secret-ldap -n ${KF_JOBS_NS}
    install
    echo "kubeflow uninstall script finished done"
    exit 0
else
    echo "kubeflow uninstall script failed."
    exit 1
fi