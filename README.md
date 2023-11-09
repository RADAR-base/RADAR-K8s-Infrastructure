# RADAR-K8s-Infrastructure
This repository aims to provide [IaC](https://en.wikipedia.org/wiki/Infrastructure_as_code) templates for [RADAR-Kubernetes](https://github.com/RADAR-base/RADAR-Kubernetes) users who intend to deploy the platform to Kubernetes clusters supported by cloud providers such as [AWS](https://aws.amazon.com/eks/). 

---

[![Terraform validate](https://github.com/phidatalab/RADAR-K8s-Infrastructure/actions/workflows/cluster.yaml/badge.svg)](https://github.com/phidatalab/RADAR-K8s-Infrastructure/actions/workflows/cluster.yaml/badge.svg)
[![Terraform validate](https://github.com/phidatalab/RADAR-K8s-Infrastructure/actions/workflows/config.yaml/badge.svg)](https://github.com/phidatalab/RADAR-K8s-Infrastructure/actions/workflows/config.yaml/badge.svg)

# Dependencies
[Terraform](https://developer.hashicorp.com/terraform/downloads) >= 1.4

# Usage
It is recommended that you use RADAR-K8s-Infrastructure as a template and create your own IaC repository from it (starting with a private one probably). Make sure to customise enclosed templates to your needs before creating the desired infrastructure.

<img src="./image/use_this_template.png" alt="use this template" width="500" height="124">


## Configure credentials
```
export TF_VAR_AWS_REGION=$AWS_REGION
export TF_VAR_AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
export TF_VAR_AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
# For temporary credentials and SSO
export TF_VAR_AWS_SESSION_TOKEN=$AWS_SESSION_TOKEN
```

## Workspaces
The definition of resources required for running RADAR-base components is located in the `cluster` directory, while other optional resources are defined in the `config` directory. Please treat each directory as a separate workspace and perform terraform operations individually. The `cluster` resources need to be created and made fully available before you proceed with the creation of the `config` ones.
| :information_source:  Important Notice  |
|:----------------------------------------|
|As a best practice, never save raw values of secret variables in your repository. Instead, always encrypt them before committing. If your cluster is no longer in use, run `terraform destory` to delete all the associated resources and reduce your cloud spending. If you have resources created within `config`, run `terraform destory` in that directory before running the counterpart in `cluster`.|

## Create the infrastructure
```
cd cluster
```
```
# Initialise the working directory

terraform init
```
```
# Review the changes going to be made 

terraform plan
```
```
# Create/update the infrastructure

terraform apply --auto-approve
```

## Configure the cluster (optional)
N.B., to get external DNS, Cert Manager and SMTP working via Route 53 (if chosen as your DNS service), you need to replace `change-me-radar-base-dummy-domain.net` with your registered second-level domain name for variable `domain_name` in `config/variables.tf`.

```
cd config
```
```
# Initialise the working directory

terraform init
```
```
# Review the changes going to be made 

terraform plan
```
```
# Create/update the infrastructure

terraform apply --auto-approve
```

Once the infrastructure update is finished successfully, you can start deploying RADAR-base components to the newly created cluster by following the [Installation Guide](https://github.com/RADAR-base/RADAR-Kubernetes#installation). Before running `helmfile sync`, You will find it necessary to configure certain resource values which are required by `production.yaml` but only known post to infrastructure creation. We have exported the values of those resources and you can get them by simply running:
```
terraform output
```
(You could also automate this configuration based on your own customisation to `production.yaml`)

## Known limitations
* Since EBS has been chosen as the default storage, node groups will be created in a single AZ due to the mounting restriction.
* Sometimes Terraform tries to replace the existing MSK cluster while re-applying the templates even if there is no change on the cluster. Mitigate this with `terraform untaint aws_msk_cluster.msk_cluster`.
* Prior to `terraform destroy`, infrastructure resources created by pods/controllers and may not be visible to Terraform need to be deleted, e.g., nginx-ingress's NLB. A good practice is to always begin by running `helmfile destroy`.
* If Karpenter is used for node provisioning, ensure the nodes created by it are not lingering around before running `terraform destroy`. 
* Due to [known issues](https://github.com/kubernetes-sigs/aws-ebs-csi-driver/issues/1507), the aws-ebs-csi-driver retains EBS volumes during cluster destruction. These volumes should be manually deleted if no longer needed.
  