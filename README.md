# RADAR-K8s-Infrastructure
This repository aims to provide [IaC](https://en.wikipedia.org/wiki/Infrastructure_as_code) templates for [RADAR-Kubernetes](https://github.com/RADAR-base/RADAR-Kubernetes) users who intend to deploy the platform to Kubernetes clusters supported by cloud providers such as [AWS](https://aws.amazon.com/eks/). 

# Dependencies
[Terraform](https://developer.hashicorp.com/terraform/downloads) >= 1.4

# Usage
It is recommended that you use RADAR-K8s-Infrastructure as a template and create your own IaC repository from it (starting with a private one probably). Make sure to customise enclosed templates to your needs before creating the desired infrastructure.

<img src="./image/use_this_template.png" alt="use this template" width="500" height="124">

## Set up environment variables
```
export TF_VAR_AWS_REGION=$AWS_REGION
export TF_VAR_AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
export TF_VAR_AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
# For temporary credentials and SSO
export TF_VAR_AWS_SESSION_TOKEN=$AWS_SESSION_TOKEN
```

## Configure your domain name (optional)
To get DNS and SMTP working, you need to replace `change-me-radar-base-dummy-domain.net` with your registered second-level domain name for variable `domain_name` in `variables.tf`.

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

Once the infrastructure update is finished successfully, you can start deploying RADAR-base components to the newly created cluster by following the [Installation Guide](https://github.com/RADAR-base/RADAR-Kubernetes#installation). Before running `helmfile sync`, You will find it necessary to configure certain resource values which are required by `production.yaml` but only known post to infrastructure creation. We have exported the values of those resources and you can get them by simply running:
```
terraform output
```
(You could also automate this configuration based on your own customisation to `production.yaml`)

## Known limits
* Since the creation of the nginx-ingress's NLB is done inside a pod which is external to Terraform, you need to remove the NLB beforehand to make the terraform destroy command succeed.

N.B.: As a best practice, never save raw values of secret variables in your repository. Instead, always encrypt them before committing. Last but not least, if your cluster is no longer in use, run `terraform destory` to delete all the associated resources and reduce your cloud spending.