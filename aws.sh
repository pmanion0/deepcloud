#!/bin/bash
# --------------------------------------- #
#  This script helps control the launch,
#  setup, and connection to an AWS EC2
#  instance for deep learning
#
#  Make sure you have SSH keys for AWS
#  and GitHub in the locations below.
#
#  !!! YOU ALSO NEED THREE ENVIRONMENT VARS
#  TO BE SET FOR YOUR AWS CREDENTIALS !!
#     - $AWS_ACCESS_KEY_ID
#     - $AWS_SECRET_ACCESS_KEY
#     - $AWS_KEY_NAME
#
# --------------------------------------- #

GITHUB_KEY=~/.ssh/github_rsa

# --------------------------------------- #
#         RUN PARAMETER CHECKS            #
# --------------------------------------- #

ACTION=$1
OPTION=$2

if [[ -z "$ACTION" ]]; then
  echo "ERROR: Run by providing [launch|setup|connect]"
  echo "EXAMPLE: ./aws.sh launch"
  exit 1
fi

if [[ $ACTION == "launch" && -z "$OPTION" ]]; then
  echo "NOTE: No instance type provided - assuming p2.xlarge"
  echo "EXAMPLE: ./aws.sh launch p3.8xlarge"
  OPTION="p2.xlarge"
fi

if [[ $ACTION != "launch" && -z "$OPTION" ]]; then
  echo "ERROR: Please provide EC2 IP after setup command"
  echo "EXAMPLE: ./aws.sh connect 12.32.46.83"
  exit 1
fi

if [[ -z "$AWS_ACCESS_KEY_ID" || -z "$AWS_SECRET_ACCESS_KEY" || -z "$AWS_KEY_NAME" ]]; then
  echo "ERROR: You must set 3 environment variables for AWS credentials:"
  echo "  - \$AWS_ACCESS_KEY_ID: secret access ID from EC2 console"
  echo "  - \$AWS_SECRET_ACCESS_KEY: secret key password from EC2 console"
  echo "  - \$AWS_KEY_NAME: name of SSH key without .pem (located at ~/.ssh/$AWS_KEY_NAME.pem)"
  exit 1
fi

# --------------------------------------- #
#  CREATE GITHUB RSA KEY CHECK TO UPLOAD  #
# --------------------------------------- #

# If checks whether known_hosts file already exists (this file is personalzied and NOT in the repo!)
if [[ ! -f ansible/remote_files/known_hosts ]]; then
  echo "NOTE: ansible/remote_files/known_hosts not found! This is needed for AWS automation."
  echo "  Would you like to create it?"
  select yn in "Yes" "No"; do
    case $yn in
        Yes )
            echo "Adding Github.com to ansible/remote_files/known_hosts"
            ssh-keyscan github.com >> ansible/remote_files/known_hosts
            break;;
        No )
            break;;
    esac
  done
fi

if [[ ! -f ansible/remote_files/aws_credentials ]]; then
  echo "NOTE: ansible/remote_files/aws_credentials not found! This is needed for AWS automation."
  echo "  Would you like to create it?"
  select yn in "Yes" "No"; do
    case $yn in
        Yes )
            OUTFILE=ansible/remote_files/aws_credentials
            echo "Creating ansible/remote_files/aws_credentials using environment variables"
            echo "[default]" > $OUTFILE
            echo "aws_access_key_id = $AWS_ACCESS_KEY_ID" >> $OUTFILE
            echo "aws_secret_access_key = $AWS_SECRET_ACCESS_KEY" >> $OUTFILE
            break;;
        No )
            break;;
    esac
  done
fi


# --------------------------------------- #
#  RUN AWS LAUNCH / SETUP / CONNECT       #
# --------------------------------------- #

AWS_SSH_KEY=~/.ssh/$AWS_KEY_NAME.pem

if [[ $ACTION == "launch" ]]; then
  INSTANCE_TYPE=$OPTION

  echo "LAUNCHING..."
  ansible-playbook ansible/ansible-aws.yml -vv \
    -i ansible/inventory/aws_ec2.yml \
    --private-key=$AWS_SSH_KEY \
    --extra-vars "ssh_key_name=$AWS_KEY_NAME git_key_file=$GITHUB_KEY instance_type=$INSTANCE_TYPE"

elif [[ $ACTION == "connect" ]]; then
  EC2_IP_ADDRESS=$OPTION

  echo "CONNECTING TO AWS..."
  ssh -i $AWS_SSH_KEY -L 7777:127.0.0.1:8888 ec2-user@$EC2_IP_ADDRESS

fi
