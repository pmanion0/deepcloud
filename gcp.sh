#!/bin/bash
# --------------------------------------- #
#  This script helps control the launch,
#  setup, and connection to a GCP
#  instance for deep learning
#
#  !!! YOU NEED TWO ENVIRONMENT VARS
#  TO BE SET FOR YOUR GCP CREDENTIALS !!
#     - $GCP_AUTH_KIND
#     - $GCP_SERVICE_ACCOUNT_FILE
#
# --------------------------------------- #

# Define the default options
PREEMPTIBLE="no"
ZONE="us-central1-a"
PROJECT="deep-learning-232504"
ACCELERATOR_TYPE=""

# --------------------------------------- #
#         RUN PARAMETER CHECKS            #
# --------------------------------------- #

ACTION=$1
OPTION=$2

if [[ -z "$ACTION" ]]; then
  echo "ERROR: Run by providing [launch|setup|connect]"
  echo "EXAMPLE: ./gcp.sh launch"
  exit 1
fi

if [[ $ACTION == "launch" && -z "$OPTION" ]]; then
  echo "NOTE: No instance type provided - assuming n1-highmem-2"
  echo "EXAMPLE: ./gcp.sh launch n1-highmem-2"
  OPTION="n1-highmem-2"
fi

if [[ $ACTION == "connect" && -z "$OPTION" ]]; then
  echo "ERROR: Please provide GCP instance name after setup command"
  echo "EXAMPLE: ./gcp.sh connect deep-vm"
  exit 1
fi


# --------------------------------------- #
#  RUN AWS LAUNCH / SETUP / CONNECT       #
# --------------------------------------- #

if [[ $ACTION == "launch" ]]; then
  INSTANCE_TYPE=$OPTION

  echo "LAUNCHING..."
  ansible-playbook ansible/gcloud-setup.yml -vv \
    -i ansible/inventory/gcloud.gcp.yml \
    --extra-vars "project=$PROJECT zone=$ZONE preemptible=$PREEMPTIBLE instance_type=$INSTANCE_TYPE accelerator_type=$ACCELERATOR_TYPE"

elif [[ $ACTION == "connect" ]]; then
  INSTANCE_NAME=$OPTION

  echo "CONNECTING TO GCP..."
  gcloud compute --project $PROJECT ssh --zone $ZONE $INSTANCE_NAME -- -L 7777:localhost:8080

fi
