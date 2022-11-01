#!/usr/bin/env bash

. ./base-scripts/demo-magic.sh

########################
# Configure the options
########################

TYPE_SPEED=40
DEMO_PROMPT="${GREEN}➜ ${CYAN}\W "
DEMO_CMD_COLOR=$WHITE

# demo props
NAMESPACE=pds-demo

# hide the evidence
clear

if [ -z "$1" ]
then
 echo "Use ..."
 echo " $0 deployFruits"  
 echo " $0 deploySSO" 
 echo " $0 failover" 
 echo " $0 pxInfo" 
 echo " $0 delete"  
 exit
fi

if [ "$1" == "pxInfo" ]
then
  pe "oc get pods -n=kube-system -l name=portworx"
  # Show PX cluster status
  PX_POD=$(oc get pods -l name=portworx -n kube-system -o jsonpath='{.items[0].metadata.name}')
  pe "oc exec -it $PX_POD -n kube-system -- /opt/pwx/bin/pxctl status"
  # Show pds system
  pe "oc get pods -n=pds-system"
  exit
fi

if [ "$1" == "deployFruits" ]
then
  # Create the namespace
  pe "cat ./deployments/pds-demo-ns.yaml"
  pe "oc apply -f ./deployments/pds-demo-ns.yaml && oc project pds-demo"
  # Deploy the Fruits App
  p "Provision a PDS database for the Fruits App"
  p "Configure the connection properties"
  pe "oc apply -f ./deployments/fruits-app/" 
  exit
fi

if [ "$1" == "deploySSO" ]
then
  # Deploy RH SSO
  p "Provision a PDS database for RH-SSO"
  p "Configure the keycloak-db-secret"
  pe "oc apply -f ./deployments/rhsso/" 
  exit
fi

if [ "$1" == "failover" ]
then
  # Inspect the PVC Volume -> show replication
  pe "oc get pvc"
  VOL=$(oc get pvc |grep datadir-pg-fruitsdb | awk '{print $3}')
  PX_POD=$(oc get pods -l name=portworx -n kube-system -o jsonpath='{.items[0].metadata.name}')
  pe "oc exec -it $PX_POD -n kube-system -- /opt/pwx/bin/pxctl volume inspect $VOL"
  # Show the nodes
  pe "oc get pods -o wide"
  pe "oc get nodes -o wide"
  NODE=`oc get pods -o wide | grep pg-fruitsdb-.*-0 | awk '{print $7}'`
  # Disable Scheduling
  pe "oc adm cordon ${NODE}"
  POD=`oc get pods -o wide | grep pg-fruitsdb-.*-0 | awk '{print $1}'`
  # Delete the pod
  pe "oc delete pod ${POD}"
  # Enable Scheduling
  pe "oc adm uncordon ${NODE}"
  # Show the current node the pod is running on
  pe "oc get pods -o wide"
  POD=`oc get pods | grep pg-fruitsdb-.*-0 | awk '{print $1}'`
  # Log in to the pod and show the data with psql
  pe "oc exec -it $POD bash"
  exit
fi

if [ "$1" == "delete" ]
then
  pe "oc delete project $NAMESPACE"
  exit
fi
