#!/usr/bin/env python3
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

import argparse
import subprocess

# Parse the required arguments
parser = argparse.ArgumentParser(description='Setup GCP')
subparser = parser.add_subparsers(dest='command')

launch_parser = subparser.add_parser('launch', help='Launch a new GCP instance')
connect_parser = subparser.add_parser('connect', help='Connect to an existing GCP instance')


launch_parser.add_argument('--machine', required = False, default='n1-highmem-2',
        help='Machine type for the instance')
launch_parser.add_argument('--gpu', required = False, default='none',
        help='Toggles using one GPU of the provided type; types include nvidia-tesla-k80, nvidia-tesla-v100')
launch_parser.add_argument('--preemptible', required = False, default='no',
        action='store_const', const='yes',
        help='Setup a pre-emptible (spot) instance to save cost')

for p in [launch_parser, connect_parser]:
  p.add_argument('--project', required = True,
        help='Name of the project in GCP')
  p.add_argument('--instance', required = True,
        help='Name of the instance in GCP (required)')
  p.add_argument('--zone', required = False, default='us-central1-a',
        help='Runs the instance in the requested zone')

args = parser.parse_args()

# Execute the request command
if args.command == 'launch':
  print(f'''
    Launch Settings:
        Instance Name: {args.instance}
        Instance Type: {args.machine}
        GCP Project: {args.project}
        GCP Zone: {args.zone}
        GPU Type: {args.gpu}
        Is Preemptible? {args.preemptible}
  ''')

  print("LAUNCHING...")

  cmd = f'ansible-playbook ansible/gcloud-setup.yml -vv \
    -i ansible/inventory/gcloud.gcp.yml \
    --extra-vars "project={args.project} zone={args.zone} \
      preemptible={args.preemptible} instance_type={args.machine} \
      accelerator_type={args.gpu}"'

  subprocess.run(cmd, shell=True)

else:
  print(f'''
    Connect Settings:
        Instance Name: {args.instance}
  ''')

  print("CONNECTING TO GCP...")

  cmd = f'gcloud compute ssh {args.instance} --project {args.project} --zone {args.zone} -- -L 7777:localhost:8080'
  
  subprocess.run(cmd, shell=True)