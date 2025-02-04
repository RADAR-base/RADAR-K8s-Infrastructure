## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.62.0, < 6.0.0 |
| <a name="requirement_kubectl"></a> [kubectl](#requirement\_kubectl) | ~> 1.14.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 2.24.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.82.2 |
| <a name="provider_kubectl"></a> [kubectl](#provider\_kubectl) | 1.14.0 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | 2.24.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_allow_assume_eks_admins_iam_policy"></a> [allow\_assume\_eks\_admins\_iam\_policy](#module\_allow\_assume\_eks\_admins\_iam\_policy) | git::https://github.com/terraform-aws-modules/terraform-aws-iam.git//modules/iam-policy | e20e0b9a42084bbc885fd5abb18b8744810bd567 |
| <a name="module_allow_eks_access_iam_policy"></a> [allow\_eks\_access\_iam\_policy](#module\_allow\_eks\_access\_iam\_policy) | git::https://github.com/terraform-aws-modules/terraform-aws-iam.git//modules/iam-policy | e20e0b9a42084bbc885fd5abb18b8744810bd567 |
| <a name="module_ebs_csi_irsa"></a> [ebs\_csi\_irsa](#module\_ebs\_csi\_irsa) | git::https://github.com/terraform-aws-modules/terraform-aws-iam.git//modules/iam-role-for-service-accounts-eks | e20e0b9a42084bbc885fd5abb18b8744810bd567 |
| <a name="module_eks"></a> [eks](#module\_eks) | git::https://github.com/terraform-aws-modules/terraform-aws-eks.git | 2cb1fac31b0fc2dd6a236b0c0678df75819c5a3b |
| <a name="module_eks_admins_iam_role"></a> [eks\_admins\_iam\_role](#module\_eks\_admins\_iam\_role) | git::https://github.com/terraform-aws-modules/terraform-aws-iam.git//modules/iam-assumable-role | e20e0b9a42084bbc885fd5abb18b8744810bd567 |
| <a name="module_iam_user"></a> [iam\_user](#module\_iam\_user) | git::https://github.com/terraform-aws-modules/terraform-aws-iam.git//modules/iam-user | e20e0b9a42084bbc885fd5abb18b8744810bd567 |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | git::https://github.com/terraform-aws-modules/terraform-aws-vpc.git | 573f574c922782bc658f05523d0c902a4792b0a8 |
| <a name="module_vpc_cni_irsa"></a> [vpc\_cni\_irsa](#module\_vpc\_cni\_irsa) | git::https://github.com/terraform-aws-modules/terraform-aws-iam.git//modules/iam-role-for-service-accounts-eks | e20e0b9a42084bbc885fd5abb18b8744810bd567 |

## Resources

| Name | Type |
|------|------|
| [aws_iam_policy.ecr_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.ecr_pull_through_cache](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.s3_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy_attachment.eks_admins_policy_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy_attachment) | resource |
| [aws_security_group.vpc_endpoint](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group_rule.vpc_endpoint_egress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.vpc_endpoint_self_ingress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_vpc_endpoint.ecr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |
| [aws_vpc_endpoint.s3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |
| [aws_vpc_endpoint.sts](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |
| [aws_vpc_security_group_ingress_rule.vpc_endpoints_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [kubectl_manifest.ebs_storage_classes](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubernetes_annotations.set_default_storage_class](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/annotations) | resource |
| [kubernetes_annotations.unset_eks_default_gp2](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/annotations) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_AWS_ACCESS_KEY_ID"></a> [AWS\_ACCESS\_KEY\_ID](#input\_AWS\_ACCESS\_KEY\_ID) | AWS access key associated with an IAM account | `string` | `""` | no |
| <a name="input_AWS_PROFILE"></a> [AWS\_PROFILE](#input\_AWS\_PROFILE) | AWS Profile that resources are created in | `string` | `"default"` | no |
| <a name="input_AWS_REGION"></a> [AWS\_REGION](#input\_AWS\_REGION) | Target AWS region | `string` | `"eu-west-2"` | no |
| <a name="input_AWS_SECRET_ACCESS_KEY"></a> [AWS\_SECRET\_ACCESS\_KEY](#input\_AWS\_SECRET\_ACCESS\_KEY) | AWS secret key associated with the access key | `string` | `""` | no |
| <a name="input_AWS_SESSION_TOKEN"></a> [AWS\_SESSION\_TOKEN](#input\_AWS\_SESSION\_TOKEN) | Session token for temporary security credentials from AWS STS | `string` | `""` | no |
| <a name="input_common_tags"></a> [common\_tags](#input\_common\_tags) | Common tags associated to resources created | `map(string)` | <pre>{<br/>  "Environment": "dev",<br/>  "Project": "radar-base"<br/>}</pre> | no |
| <a name="input_create_dmz_node_group"></a> [create\_dmz\_node\_group](#input\_create\_dmz\_node\_group) | Whether or not to create a DMZ node group with taints | `bool` | `false` | no |
| <a name="input_default_storage_class"></a> [default\_storage\_class](#input\_default\_storage\_class) | Default storage class used for describing the EBS usage | `string` | `"radar-base-ebs-sc-gp2"` | no |
| <a name="input_dmz_node_size"></a> [dmz\_node\_size](#input\_dmz\_node\_size) | Node size of the DMZ node group | `map(number)` | <pre>{<br/>  "desired": 1,<br/>  "max": 2,<br/>  "min": 0<br/>}</pre> | no |
| <a name="input_ecr_repository_names"></a> [ecr\_repository\_names](#input\_ecr\_repository\_names) | Default prefixes for ECR repositories if used for hosting the images | `list(string)` | <pre>[<br/>  "ecr-public*",<br/>  "k8s*",<br/>  "quay*",<br/>  "docker-hub*",<br/>  "radarbase*"<br/>]</pre> | no |
| <a name="input_eks_admins_group_users"></a> [eks\_admins\_group\_users](#input\_eks\_admins\_group\_users) | EKS admin IAM user group | `list(string)` | `[]` | no |
| <a name="input_eks_cluster_name"></a> [eks\_cluster\_name](#input\_eks\_cluster\_name) | EKS cluster name | `string` | n/a | yes |
| <a name="input_eks_kubernetes_version"></a> [eks\_kubernetes\_version](#input\_eks\_kubernetes\_version) | Amazon EKS Kubernetes version | `string` | `"1.31"` | no |
| <a name="input_instance_capacity_type"></a> [instance\_capacity\_type](#input\_instance\_capacity\_type) | Capacity type used by EKS managed node groups | `string` | `"SPOT"` | no |
| <a name="input_instance_types"></a> [instance\_types](#input\_instance\_types) | List of instance types used by EKS managed node groups | `list(any)` | <pre>[<br/>  "m5.large",<br/>  "m5d.large",<br/>  "m5a.large",<br/>  "m5ad.large",<br/>  "m4.large"<br/>]</pre> | no |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | VPC CIDR | `string` | `"10.0.0.0/16"` | no |
| <a name="input_vpc_private_subnet_cidr"></a> [vpc\_private\_subnet\_cidr](#input\_vpc\_private\_subnet\_cidr) | List of private subnet configurations | `list(any)` | <pre>[<br/>  "10.0.0.0/19",<br/>  "10.0.32.0/19",<br/>  "10.0.64.0/19"<br/>]</pre> | no |
| <a name="input_vpc_public_subnet_cidr"></a> [vpc\_public\_subnet\_cidr](#input\_vpc\_public\_subnet\_cidr) | List of public subnet configurations | `list(any)` | <pre>[<br/>  "10.0.96.0/19",<br/>  "10.0.128.0/19",<br/>  "10.0.160.0/19"<br/>]</pre> | no |
| <a name="input_worker_node_size"></a> [worker\_node\_size](#input\_worker\_node\_size) | Node size of the worker node group | `map(number)` | <pre>{<br/>  "desired": 2,<br/>  "max": 10,<br/>  "min": 0<br/>}</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_assume_eks_admins_role"></a> [assume\_eks\_admins\_role](#output\_assume\_eks\_admins\_role) | EKS admin role ARN |
| <a name="output_radar_base_default_storage_class"></a> [radar\_base\_default\_storage\_class](#output\_radar\_base\_default\_storage\_class) | n/a |
| <a name="output_radar_base_eks_cluster_endpoint"></a> [radar\_base\_eks\_cluster\_endpoint](#output\_radar\_base\_eks\_cluster\_endpoint) | n/a |
| <a name="output_radar_base_eks_cluster_kms_key_arn"></a> [radar\_base\_eks\_cluster\_kms\_key\_arn](#output\_radar\_base\_eks\_cluster\_kms\_key\_arn) | n/a |
| <a name="output_radar_base_eks_cluster_name"></a> [radar\_base\_eks\_cluster\_name](#output\_radar\_base\_eks\_cluster\_name) | n/a |
| <a name="output_radar_base_eks_dmz_node_group_name"></a> [radar\_base\_eks\_dmz\_node\_group\_name](#output\_radar\_base\_eks\_dmz\_node\_group\_name) | n/a |
| <a name="output_radar_base_eks_worker_node_group_name"></a> [radar\_base\_eks\_worker\_node\_group\_name](#output\_radar\_base\_eks\_worker\_node\_group\_name) | n/a |
| <a name="output_radar_base_vpc_public_subnets"></a> [radar\_base\_vpc\_public\_subnets](#output\_radar\_base\_vpc\_public\_subnets) | n/a |