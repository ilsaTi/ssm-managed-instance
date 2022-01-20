#!/bin/bash
# initiate terraform in the main folder
terraform init
# validate the code
terraform validate
# deploy
terraform apply