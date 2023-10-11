#!/bin/bash

LANG=C
SLEEP_SECONDS=30

ACM_OPERATOR_PATH="components/operators/advanced-cluster-management/operator/overlays/release-2.8"
ACM_INSTANCE_PATH="components/operators/advanced-cluster-management/instance/overlays/default"
ACM_POLICIES_PATH="bootstrap/policies/overlays/default"

echo ""
echo "Installing RHACM Operator."

kustomize build ${ACM_OPERATOR_PATH} | oc apply -f -

echo "Pause $SLEEP_SECONDS seconds for the creation of the rhacm-operator..."
sleep $SLEEP_SECONDS

echo "Waiting for operator to start"
until oc get deployment multiclusterhub-operator -n open-cluster-management
do
  sleep 10;
done

echo "Installing the MultiClusterHub"

kustomize build ${ACM_INSTANCE_PATH} | oc apply -f -

echo "Waiting for hub to be installed"

until [[ $(oc get multiclusterhub multiclusterhub -n open-cluster-management -o jsonpath='{.status.phase}') == 'Running' ]]
do
  echo "Waiting for hub, current status:"
  oc get multiclusterhub multiclusterhub -n open-cluster-management
  sleep 10
done

# echo "Installing policies and initial secrets"

# kustomize build bootstrap/secrets/base | oc apply -f -
kustomize build ${ACM_POLICIES_PATH} --enable-alpha-plugins | oc apply -f -

# echo "Labeling cluster with 'gitops: local.home'"
oc label managedcluster local-cluster gitops=acm-hub --overwrite=true
oc label managedcluster local-cluster environment=development --overwrite=true

echo "Check policy compliance with the following command:"
echo "  oc get policy -A"

echo "Once GitOps configuration is complete you may need to run the following to fix Unknown status\n"
echo "  oc delete secret local-cluster-import -n local-cluster\n"
