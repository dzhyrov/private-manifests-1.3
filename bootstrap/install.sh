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

deploy_cert_manager()
{
    kubectl apply -k ${MANIFESTS_DIR}/common/cert-manager/cert-manager-kube-system-resources/base && \
    kubectl apply -k ${MANIFESTS_DIR}/common/cert-manager/cert-manager-crds/base && \
    kubectl apply -k ${MANIFESTS_DIR}/common/cert-manager/cert-manager/overlays/self-signed
}

deploy_istio()
{
    kubectl apply -k ${MANIFESTS_DIR}/common/istio-1-9-0/istio-crds/base && \
    kubectl apply -k ${MANIFESTS_DIR}/common/istio-1-9-0/istio-namespace/base && \
    kubectl apply -k ${MANIFESTS_DIR}/common/istio-1-9-0/istio-install/base
}

deploy_authservices()
{
    kubectl apply -k ${MANIFESTS_DIR}/common/oidc-authservice/base && \
    kubectl apply -k ${MANIFESTS_DIR}/common/dex/overlays/istio
}

deploy_knative()
{
    kubectl apply -k ${MANIFESTS_DIR}/common/knative/knative-serving-crds/base && \
    kubectl apply -k ${MANIFESTS_DIR}/common/knative/knative-serving-install/base && \
    kubectl apply -k ${MANIFESTS_DIR}/common/knative/knative-eventing-crds/base && \
    kubectl apply -k ${MANIFESTS_DIR}/common/knative/knative-eventing-install/base
}

deploy_cluster_local_gateway()
{
    kubectl apply -k ${MANIFESTS_DIR}/common/istio-1-9-0/cluster-local-gateway/base
}

deploy_kf_services()
{
    kubectl apply -k ${MANIFESTS_DIR}/common/kubeflow-namespace/base && \
    kubectl apply -k ${MANIFESTS_DIR}/common/kubeflow-roles/base && \
    kubectl apply -k ${MANIFESTS_DIR}/common/istio-1-9-0/kubeflow-istio-resources/base && \
    kubectl apply -k ${MANIFESTS_DIR}/apps/pipeline/upstream/env/platform-agnostic-multi-user && \
    kubectl apply -k ${MANIFESTS_DIR}/apps/kfserving/upstream/overlays/kubeflow && \
    kubectl apply -k ${MANIFESTS_DIR}/apps/katib/upstream/installs/katib-with-kubeflow && \
    kubectl apply -k ${MANIFESTS_DIR}/apps/centraldashboard/upstream/overlays/istio && \
    kubectl apply -k ${MANIFESTS_DIR}/apps/admission-webhook/upstream/overlays/cert-manager && \
    kubectl apply -k ${MANIFESTS_DIR}/apps/jupyter/jupyter-web-app/upstream/overlays/istio && \
    kubectl apply -k ${MANIFESTS_DIR}/apps/jupyter/notebook-controller/upstream/overlays/kubeflow && \
    kubectl apply -k ${MANIFESTS_DIR}/apps/profiles/upstream/overlays/kubeflow && \
    kubectl apply -k ${MANIFESTS_DIR}/apps/volumes-web-app/upstream/overlays/istio && \
    kubectl apply -k ${MANIFESTS_DIR}/apps/tensorboard/tensorboard-controller/upstream/overlays/kubeflow && \
    kubectl apply -k ${MANIFESTS_DIR}/apps/tensorboard/tensorboards-web-app/upstream/overlays/istio && \
    kubectl apply -k ${MANIFESTS_DIR}/apps/tf-training/upstream/overlays/kubeflow && \
    kubectl apply -k ${MANIFESTS_DIR}/apps/pytorch-job/upstream/overlays/kubeflow && \
    kubectl apply -k ${MANIFESTS_DIR}/apps/mpi-job/upstream/overlays/kubeflow && \
    kubectl apply -k ${MANIFESTS_DIR}/apps/mxnet-job/upstream/overlays/kubeflow && \
    kubectl apply -k ${MANIFESTS_DIR}/apps/xgboost-job/upstream/overlays/kubeflow && \
    kubectl apply -k ${MANIFESTS_DIR}/common/user-namespace/base
}

install()
{    
    printf "\nTrying to deploy cert manager...\n\n"
    while ! deploy_cert_manager; do printf "\n*** Retrying to deploy cert manager... ***\n\n"; sleep ${RETRY_TIMEOUT}; done

    if [ ${DISABLE_ISTIO} != true ]; then
        printf "\nTrying to deploy istio...\n\n"
        while ! deploy_istio; do printf "\n*** Retrying to deploy istio... ***\n\n"; sleep ${RETRY_TIMEOUT}; done
    fi

    printf "\nTrying to deploy authservices...\n\n"
    while ! deploy_authservices; do printf "\n*** Retrying to deploy authservices... ***\n\n"; sleep ${RETRY_TIMEOUT}; done

    printf "\nTrying to deploy knative...\n\n"
    while ! deploy_knative; do printf "\n*** Retrying to deploy knative... ***\n\n"; sleep ${RETRY_TIMEOUT}; done

    if [ ${DISABLE_ISTIO} != true ]; then
        printf "\nTrying to deploy cluster local gateway...\n\n"
        while ! deploy_cluster_local_gateway; do printf "\n*** Retrying to deploy cluster local gateway... ***\n\n"; sleep ${RETRY_TIMEOUT}; done
    fi

    printf "\nTrying to deploy kubeflow services...\n\n"
    while ! deploy_kf_services; do printf "\n*** Retrying to deploy kubeflow services... ***\n\n"; sleep ${RETRY_TIMEOUT}; done
}


if test_env_vars; then
    # kubectl create ns ${KF_JOBS_NS}
    # kubectl apply -f ips.yaml
    # kubectl apply -k ./components/dex-secret-ldap -n ${KF_JOBS_NS}
    install
    echo "kubeflow install script finished done"
    exit 0
else
    echo "kubeflow install script failed."
    exit 1
fi