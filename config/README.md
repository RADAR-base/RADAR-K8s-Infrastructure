## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0 |
| <a name="requirement_archive"></a> [archive](#requirement\_archive) | ~> 2.7.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.62.0, < 6.0.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 2.11.0 |
| <a name="requirement_kubectl"></a> [kubectl](#requirement\_kubectl) | ~> 1.14.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 2.24.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_archive"></a> [archive](#provider\_archive) | 2.7.0 |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.82.2 |
| <a name="provider_helm"></a> [helm](#provider\_helm) | 2.11.0 |
| <a name="provider_kubectl"></a> [kubectl](#provider\_kubectl) | 1.14.0 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | 2.24.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_cert_manager_irsa"></a> [cert\_manager\_irsa](#module\_cert\_manager\_irsa) | git::https://github.com/terraform-aws-modules/terraform-aws-iam.git//modules/iam-role-for-service-accounts-eks | e20e0b9a42084bbc885fd5abb18b8744810bd567 |
| <a name="module_external_dns_irsa"></a> [external\_dns\_irsa](#module\_external\_dns\_irsa) | git::https://github.com/terraform-aws-modules/terraform-aws-iam.git//modules/iam-role-for-service-accounts-eks | e20e0b9a42084bbc885fd5abb18b8744810bd567 |
| <a name="module_karpenter"></a> [karpenter](#module\_karpenter) | git::https://github.com/terraform-aws-modules/terraform-aws-eks.git//modules/karpenter | 2cb1fac31b0fc2dd6a236b0c0678df75819c5a3b |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_group.msk_broker](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_db_instance.radar_postgres](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance) | resource |
| [aws_db_subnet_group.rds_subnet](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_subnet_group) | resource |
| [aws_ecr_pull_through_cache_rule.dockerhub](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_pull_through_cache_rule) | resource |
| [aws_ecr_repository_creation_template.dockerhub](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository_creation_template) | resource |
| [aws_eip.cluster_loadbalancer_eip](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_iam_access_key.s3_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_access_key) | resource |
| [aws_iam_access_key.smtp_user_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_access_key) | resource |
| [aws_iam_policy.s3_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.smtp_user_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.msk_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.secret_rotation_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.secret_rotation_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.msk_policy_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_user.s3_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_user) | resource |
| [aws_iam_user.smtp_user](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_user) | resource |
| [aws_iam_user_policy_attachment.s3_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_user_policy_attachment) | resource |
| [aws_iam_user_policy_attachment.smtp_user_policy_attach](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_user_policy_attachment) | resource |
| [aws_lambda_function.secret_rotation_function](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_lambda_permission.secrets_manager_invoke](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_msk_cluster.msk_cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/msk_cluster) | resource |
| [aws_msk_configuration.msk_configuration](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/msk_configuration) | resource |
| [aws_route53_record.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.smtp_dkim_record](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.smtp_mail_from_mx](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.smtp_mail_from_txt](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_zone.primary](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_zone) | resource |
| [aws_s3_bucket.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_acl.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_acl) | resource |
| [aws_s3_bucket_ownership_controls.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_ownership_controls) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_secretsmanager_secret.dockerhub_credentials](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret_rotation.dockerhub](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_rotation) | resource |
| [aws_secretsmanager_secret_version.dockerhub_credentials_version](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [aws_security_group.msk_cluster_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.rds_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_ses_domain_dkim.smtp_dkim](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ses_domain_dkim) | resource |
| [aws_ses_domain_identity.smtp_identity](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ses_domain_identity) | resource |
| [aws_ses_domain_mail_from.smtp_mail_from](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ses_domain_mail_from) | resource |
| [helm_release.karpenter](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.kubernetes_dashboard](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.metrics_server](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubectl_manifest.create_databases_if_not_exist](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubectl_manifest.karpenter_node_template](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubectl_manifest.karpenter_provisioner](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubernetes_cluster_role_binding_v1.dashboard_user](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/cluster_role_binding_v1) | resource |
| [kubernetes_cluster_role_v1.read_only](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/cluster_role_v1) | resource |
| [kubernetes_namespace.kubernetes_dashboard](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_secret_v1.dashboard_user](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret_v1) | resource |
| [kubernetes_service_account_v1.dashboard_user](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service_account_v1) | resource |
| [archive_file.secret_rotation_lambda_artifact](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |
| [aws_eks_cluster.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster) | data source |
| [aws_eks_cluster_auth.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster_auth) | data source |
| [aws_eks_node_group.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_node_group) | data source |
| [aws_eks_node_groups.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_node_groups) | data source |
| [aws_security_group.node](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/security_group) | data source |
| [aws_security_group.vpc_default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/security_group) | data source |
| [aws_subnet.private_subnet](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet) | data source |
| [aws_subnets.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnets) | data source |
| [aws_vpc.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_AWS_ACCESS_KEY_ID"></a> [AWS\_ACCESS\_KEY\_ID](#input\_AWS\_ACCESS\_KEY\_ID) | AWS access key associated with an IAM account | `string` | n/a | yes |
| <a name="input_AWS_PROFILE"></a> [AWS\_PROFILE](#input\_AWS\_PROFILE) | AWS Profile that resources are created in | `string` | `"default"` | no |
| <a name="input_AWS_REGION"></a> [AWS\_REGION](#input\_AWS\_REGION) | Target AWS region | `string` | `"eu-west-2"` | no |
| <a name="input_AWS_SECRET_ACCESS_KEY"></a> [AWS\_SECRET\_ACCESS\_KEY](#input\_AWS\_SECRET\_ACCESS\_KEY) | AWS secret key associated with the access key | `string` | n/a | yes |
| <a name="input_AWS_SESSION_TOKEN"></a> [AWS\_SESSION\_TOKEN](#input\_AWS\_SESSION\_TOKEN) | Session token for temporary security credentials from AWS STS | `string` | `""` | no |
| <a name="input_common_tags"></a> [common\_tags](#input\_common\_tags) | Common tags associated to resources created | `map(string)` | <pre>{<br/>  "Environment": "dev",<br/>  "Project": "radar-base"<br/>}</pre> | no |
| <a name="input_docker_hub_access_token"></a> [docker\_hub\_access\_token](#input\_docker\_hub\_access\_token) | Docker Hub access token for ECR pull through cache | `string` | n/a | yes |
| <a name="input_docker_hub_username"></a> [docker\_hub\_username](#input\_docker\_hub\_username) | Docker Hub username for ECR pull through cache | `string` | n/a | yes |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | Pair of top level domain and hosted zone ID for deployed applications | `map(string)` | `{}` | no |
| <a name="input_eks_cluster_name"></a> [eks\_cluster\_name](#input\_eks\_cluster\_name) | EKS cluster name | `string` | n/a | yes |
| <a name="input_enable_ecr_ptc"></a> [enable\_ecr\_ptc](#input\_enable\_ecr\_ptc) | Do you need ECR pull-through cache? [true, false] | `bool` | n/a | yes |
| <a name="input_enable_eip"></a> [enable\_eip](#input\_enable\_eip) | Do you need EIP? [true, false] | `bool` | n/a | yes |
| <a name="input_enable_karpenter"></a> [enable\_karpenter](#input\_enable\_karpenter) | Do you need Karpenter? [true, false] | `bool` | n/a | yes |
| <a name="input_enable_metrics"></a> [enable\_metrics](#input\_enable\_metrics) | Do you need Metrics Server? [true, false] | `bool` | n/a | yes |
| <a name="input_enable_msk"></a> [enable\_msk](#input\_enable\_msk) | Do you need MSK? [true, false] | `bool` | n/a | yes |
| <a name="input_enable_msk_logging"></a> [enable\_msk\_logging](#input\_enable\_msk\_logging) | Do you need logging on MSK brokers? [true, false] | `bool` | n/a | yes |
| <a name="input_enable_rds"></a> [enable\_rds](#input\_enable\_rds) | Do you need RDS? [true, false] | `bool` | n/a | yes |
| <a name="input_enable_route53"></a> [enable\_route53](#input\_enable\_route53) | Do you need Route53? [true, false] | `bool` | n/a | yes |
| <a name="input_enable_s3"></a> [enable\_s3](#input\_enable\_s3) | Do you need S3? [true, false] | `bool` | n/a | yes |
| <a name="input_enable_ses"></a> [enable\_ses](#input\_enable\_ses) | Do you need SES? [true, false] | `bool` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name | `string` | `"dev"` | no |
| <a name="input_instance_capacity_type"></a> [instance\_capacity\_type](#input\_instance\_capacity\_type) | Capacity type used by EKS managed node groups | `string` | `"SPOT"` | no |
| <a name="input_kafka_version"></a> [kafka\_version](#input\_kafka\_version) | n/a | `string` | `"3.2.0"` | no |
| <a name="input_karpenter_version"></a> [karpenter\_version](#input\_karpenter\_version) | n/a | `string` | `"v0.29.0"` | no |
| <a name="input_kubernetes_dashboard_version"></a> [kubernetes\_dashboard\_version](#input\_kubernetes\_dashboard\_version) | n/a | `string` | `"7.3.2"` | no |
| <a name="input_metrics_server_version"></a> [metrics\_server\_version](#input\_metrics\_server\_version) | n/a | `string` | `"3.12.1"` | no |
| <a name="input_postgres_version"></a> [postgres\_version](#input\_postgres\_version) | n/a | `string` | `"13.14"` | no |
| <a name="input_radar_postgres_password"></a> [radar\_postgres\_password](#input\_radar\_postgres\_password) | Password for the PostgreSQL database used by Radar components | `string` | n/a | yes |
| <a name="input_with_dmz_pods"></a> [with\_dmz\_pods](#input\_with\_dmz\_pods) | Whether or not to utilise the DMZ node group if it exists | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_radar_base_eip_allocation_id"></a> [radar\_base\_eip\_allocation\_id](#output\_radar\_base\_eip\_allocation\_id) | n/a |
| <a name="output_radar_base_eip_public_dns"></a> [radar\_base\_eip\_public\_dns](#output\_radar\_base\_eip\_public\_dns) | n/a |
| <a name="output_radar_base_k8s_dashboard_user_token"></a> [radar\_base\_k8s\_dashboard\_user\_token](#output\_radar\_base\_k8s\_dashboard\_user\_token) | n/a |
| <a name="output_radar_base_msk_bootstrap_brokers"></a> [radar\_base\_msk\_bootstrap\_brokers](#output\_radar\_base\_msk\_bootstrap\_brokers) | n/a |
| <a name="output_radar_base_msk_zookeeper_connect"></a> [radar\_base\_msk\_zookeeper\_connect](#output\_radar\_base\_msk\_zookeeper\_connect) | n/a |
| <a name="output_radar_base_rds_appserver_host"></a> [radar\_base\_rds\_appserver\_host](#output\_radar\_base\_rds\_appserver\_host) | n/a |
| <a name="output_radar_base_rds_appserver_password"></a> [radar\_base\_rds\_appserver\_password](#output\_radar\_base\_rds\_appserver\_password) | n/a |
| <a name="output_radar_base_rds_appserver_port"></a> [radar\_base\_rds\_appserver\_port](#output\_radar\_base\_rds\_appserver\_port) | n/a |
| <a name="output_radar_base_rds_appserver_username"></a> [radar\_base\_rds\_appserver\_username](#output\_radar\_base\_rds\_appserver\_username) | n/a |
| <a name="output_radar_base_rds_managementportal_host"></a> [radar\_base\_rds\_managementportal\_host](#output\_radar\_base\_rds\_managementportal\_host) | n/a |
| <a name="output_radar_base_rds_managementportal_password"></a> [radar\_base\_rds\_managementportal\_password](#output\_radar\_base\_rds\_managementportal\_password) | n/a |
| <a name="output_radar_base_rds_managementportal_port"></a> [radar\_base\_rds\_managementportal\_port](#output\_radar\_base\_rds\_managementportal\_port) | n/a |
| <a name="output_radar_base_rds_managementportal_username"></a> [radar\_base\_rds\_managementportal\_username](#output\_radar\_base\_rds\_managementportal\_username) | n/a |
| <a name="output_radar_base_rds_rest_sources_auth_host"></a> [radar\_base\_rds\_rest\_sources\_auth\_host](#output\_radar\_base\_rds\_rest\_sources\_auth\_host) | n/a |
| <a name="output_radar_base_rds_rest_sources_auth_password"></a> [radar\_base\_rds\_rest\_sources\_auth\_password](#output\_radar\_base\_rds\_rest\_sources\_auth\_password) | n/a |
| <a name="output_radar_base_rds_rest_sources_auth_port"></a> [radar\_base\_rds\_rest\_sources\_auth\_port](#output\_radar\_base\_rds\_rest\_sources\_auth\_port) | n/a |
| <a name="output_radar_base_rds_rest_sources_auth_username"></a> [radar\_base\_rds\_rest\_sources\_auth\_username](#output\_radar\_base\_rds\_rest\_sources\_auth\_username) | n/a |
| <a name="output_radar_base_route53_hosted_zone_id"></a> [radar\_base\_route53\_hosted\_zone\_id](#output\_radar\_base\_route53\_hosted\_zone\_id) | n/a |
| <a name="output_radar_base_s3_access_key"></a> [radar\_base\_s3\_access\_key](#output\_radar\_base\_s3\_access\_key) | n/a |
| <a name="output_radar_base_s3_intermediate_output_bucket_name"></a> [radar\_base\_s3\_intermediate\_output\_bucket\_name](#output\_radar\_base\_s3\_intermediate\_output\_bucket\_name) | n/a |
| <a name="output_radar_base_s3_output_bucket_name"></a> [radar\_base\_s3\_output\_bucket\_name](#output\_radar\_base\_s3\_output\_bucket\_name) | n/a |
| <a name="output_radar_base_s3_secret_key"></a> [radar\_base\_s3\_secret\_key](#output\_radar\_base\_s3\_secret\_key) | n/a |
| <a name="output_radar_base_s3_velero_bucket_name"></a> [radar\_base\_s3\_velero\_bucket\_name](#output\_radar\_base\_s3\_velero\_bucket\_name) | n/a |
| <a name="output_radar_base_smtp_host"></a> [radar\_base\_smtp\_host](#output\_radar\_base\_smtp\_host) | n/a |
| <a name="output_radar_base_smtp_password"></a> [radar\_base\_smtp\_password](#output\_radar\_base\_smtp\_password) | n/a |
| <a name="output_radar_base_smtp_port"></a> [radar\_base\_smtp\_port](#output\_radar\_base\_smtp\_port) | n/a |
| <a name="output_radar_base_smtp_username"></a> [radar\_base\_smtp\_username](#output\_radar\_base\_smtp\_username) | n/a |