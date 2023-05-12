# RADAR-K8s-Infrastructure
This repository aims to provide [IaC](https://en.wikipedia.org/wiki/Infrastructure_as_code) templates for [RADAR-Kubernetes](https://github.com/RADAR-base/RADAR-Kubernetes) users who intend to deploy the platform to Kubernetes clusters supported by cloud providers such as [AWS](https://aws.amazon.com/eks/). 

# Dependencies
[Terraform](https://developer.hashicorp.com/terraform/downloads) >= 1.4

# Usage
It is recommended that you use RADAR-K8s-Infrastructure as a template and create your own IaC repository from it (starting with a private one probably). Make sure to customise enclosed templates to your needs before creating the desired infrastructure.

<img src="./image/use_this_template.png" alt="use this template" width="500" height="124">

## Set up environment variables
```
export TF_VAR_AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
export TF_VAR_AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
# For temporary credentials and SSO
export TF_VAR_AWS_SESSION_TOKEN=$AWS_SESSION_TOKEN
```

## Initialise the infrastructure directory
```
terraform init
```

## Review the changes going to be made 
```
terraform plan
```

## Create/update the infrastructure
```
terraform apply --auto-approve
```

N.B.: As a best practice, never save raw values of secret variables in your repository. Instead, always encrypt them before committing. Last but not least, if your cluster is on longer in use, run `terraform destory` to delete all the resources associated with it and reduce your cloud spending.