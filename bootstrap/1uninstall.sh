KF_JOBS_NS=${KF_JOBS_NS:-kubeflow-jobs}
MANIFESTS_DIR=../private-manifests

kubectl delete --wait -k ${MANIFESTS_DIR}/example
# kubectl delete -k ./components/dex-secret-ldap -n ${KF_JOBS_NS}
# kubectl delete ns ${KF_JOBS_NS}
kubectl wait ns kubeflow --for=condition=terminated --timeout=40s