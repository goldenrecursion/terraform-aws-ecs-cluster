Terraform AWS ECS Cluster
=========================

[![CircleCI](https://circleci.com/gh/infrablocks/terraform-aws-ecs-cluster.svg?style=svg)](https://circleci.com/gh/infrablocks/terraform-aws-ecs-cluster)

A Terraform module for building an ECS Cluster in AWS.

The ECS cluster requires:
* An existing VPC
* Some existing subnets

The ECS cluster consists of:
* A cluster in ECS
* A launch configuration and auto-scaling group for a cluster of ECS container
  instances
* An SSH key to connect to the ECS container instances
* A security group for the container instances optionally allowing:
  * Outbound internet access for all containers
  * Inbound TCP access on any port from the VPC network
* An IAM role and policy for the container instances allowing:
  * ECS interactions
  * ECR image pulls
  * S3 object fetches
  * Logging to cloudwatch
* An IAM role and policy for ECS services allowing:
  * Elastic load balancer registration / deregistration
  * EC2 describe actions and security group ingress rule creation
* A CloudWatch log group

![Diagram of infrastructure managed by this module](https://raw.githubusercontent.com/infrablocks/terraform-aws-ecs-cluster/main/docs/architecture.png)

Usage
-----

To use the module, include something like the following in your terraform
configuration:

```hcl-terraform
module "ecs_cluster" {
  source = "infrablocks/ecs-cluster/aws"
  version = "3.4.0"

  region = "eu-west-2"
  vpc_id = "vpc-fb7dc365"
  subnet_ids = "subnet-eb32c271,subnet-64872d1f"

  component = "important-component"
  deployment_identifier = "production"

  cluster_name = "services"
  cluster_instance_ssh_public_key_path = "~/.ssh/id_rsa.pub"
  cluster_instance_type = "t2.small"

  cluster_minimum_size = 2
  cluster_maximum_size = 10
  cluster_desired_capacity = 4
}
```

As mentioned above, the ECS cluster deploys into an existing base network.
Whilst the base network can be created using any mechanism you like, the
[AWS Base Networking](https://github.com/infrablocks/terraform-aws-base-networking)
module will create everything you need. See the
[docs](https://github.com/infrablocks/terraform-aws-base-networking/blob/main/README.md)
for usage instructions.

See the
[Terraform registry entry](https://registry.terraform.io/modules/infrablocks/ecs-cluster/aws/latest)
for more details.

### Inputs

| Name                                       | Description                                                                                                      | Default            | Required                                 |
|--------------------------------------------|------------------------------------------------------------------------------------------------------------------|:------------------:|:----------------------------------------:|
| region                                     | The region into which to deploy the cluster                                                                      | -                  | yes                                      |
| vpc_id                                     | The ID of the VPC into which to deploy the cluster                                                               | -                  | yes                                      |
| subnet_ids                                 | The IDs of the subnets for container instances                                                                   | -                  | yes                                      |
| component                                  | The component this cluster will contain                                                                          | -                  | yes                                      |
| deployment_identifier                      | An identifier for this instantiation                                                                             | -                  | yes                                      |
| tags                                       | A map of additional tags to add to all resources                                                                 | -                  | no                                       |
| cluster_name                               | The name of the cluster to create                                                                                | default            | yes                                      |
| cluster_instance_ssh_public_key_path       | The path to the public key to use for the container instances                                                    | -                  | yes                                      |
| cluster_instance_type                      | The instance type of the container instances                                                                     | t2.medium          | yes                                      |
| cluster_instance_root_block_device_size    | The size in GB of the root block device on cluster instances                                                     | 30                 | yes                                      |
| cluster_instance_root_block_device_type    | The type of the root block device on cluster instances ('standard', 'gp2', or 'io1')                             | standard           | yes                                      |
| cluster_instance_user_data_template        | The contents of a template for container instance user data                                                      | see user-data      | no                                       |
| cluster_instance_amis                      | A map of regions to AMIs for the container instances                                                             | ECS optimised AMIs | yes                                      |
| cluster_instance_iam_policy_contents       | The contents of the cluster instance IAM policy                                                                  | see policies       | no                                       |
| cluster_service_iam_policy_contents        | The contents of the cluster service IAM policy                                                                   | see policies       | no                                       |
| cluster_minimum_size                       | The minimum size of the ECS cluster                                                                              | 1                  | yes                                      |
| cluster_maximum_size                       | The maximum size of the ECS cluster                                                                              | 10                 | yes                                      |
| cluster_desired_capacity                   | The desired capacity of the ECS cluster                                                                          | 3                  | yes                                      |
| associate_public_ip_addresses              | Whether or not to associate public IP addresses with ECS container instances ("yes" or "no")                     | "no"               | yes                                      |
| include_default_ingress_rule               | Whether or not to include the default ingress rule on the ECS container instances security group ("yes" or "no") | "yes"              | yes                                      |
| include_default_egress_rule                | Whether or not to include the default egress rule on the ECS container instances security group ("yes" or "no")  | "yes"              | yes                                      |
| allowed_cidrs                              | The CIDRs allowed access to containers                                                                           | ["10.0.0.0/8"]     | if include_default_ingress_rule is "yes" |
| egress_cidrs                               | The CIDRs accessible from containers                                                                             | ["0.0.0.0/0"]      | if include_default_egress_rule is "yes"  |
| launch_configuration_create_before_destroy | Whether or not to destroy the launch configuration before creating a new one ("yes" or "no")                     | "yes"              | no                                       |
| security_groups                            | The list of security group IDs to associate with the cluster in addition to the default security group           | []                 | no                                       |

Notes:
* By default, the latest available Amazon Linux 2 AMI is used.
* For Amazon Linux 1 AMIs use version <= 0.6.0 of this module for terraform 0.11
  or version = 1.0.0 for terraform 0.12.
* When a specific AMI is provided via `cluster_instance_amis` (a map of region
  to AMI ID), only the root block device can be customised, using the
  `cluster_instance_root_block_device_size` and
  `cluster_instance_root_block_device_type` variables.
* The user data template will get the cluster name as `cluster_name`. If
  none is supplied, a default will be used.

### Outputs

| Name                      | Description                                                                      |
|---------------------------|----------------------------------------------------------------------------------|
| cluster_id                | The ID of the created ECS cluster                                                |
| cluster_name              | The name of the created ECS cluster                                              |
| cluster_arn               | The ARN of the created ECS cluster                                               |
| autoscaling_group_name    | The name of the autoscaling group for the ECS container instances                |
| launch_configuration_name | The name of the launch configuration for the ECS container instances             |
| security_group_id         | The ID of the default security group associated with the ECS container instances |
| instance_role_arn         | The ARN of the container instance role                                           |
| instance_role_id          | The ID of the container instance role                                            |
| instance_policy_arn       | The ARN of the container instance policy                                         |
| instance_policy_id        | The ID of the container instance policy                                          |
| service_role_arn          | The ARN of the ECS service role                                                  |
| service_role_id           | The ID of the ECS service role                                                   |
| service_policy_arn        | The ARN of the ECS service policy                                                |
| service_policy_id         | The ID of the ECS service policy                                                 |
| log_group                 | The name of the default log group for the cluster                                |

### Compatibility

This module is compatible with Terraform versions greater than or equal to
Terraform 0.14.

### Required Permissions

* iam:GetPolicy
* iam:GetPolicyVersion
* iam:ListPolicyVersions
* iam:ListEntitiesForPolicy
* iam:CreatePolicy
* iam:DeletePolicy
* iam:GetRole
* iam:PassRole
* iam:CreateRole
* iam:DeleteRole
* iam:ListRolePolicies
* iam:AttachRolePolicy
* iam:DetachRolePolicy
* iam:GetInstanceProfile
* iam:CreateInstanceProfile
* iam:ListInstanceProfilesForRole
* iam:AddRoleToInstanceProfile
* iam:RemoveRoleFromInstanceProfile
* iam:DeleteInstanceProfile
* ec2:DescribeSecurityGroups
* ec2:CreateSecurityGroup
* ec2:DeleteSecurityGroup
* ec2:AuthorizeSecurityGroupIngress
* ec2:AuthorizeSecurityGroupEgress
* ec2:RevokeSecurityGroupEgress
* ec2:ImportKeyPair
* ec2:DescribeKeyPairs
* ec2:DeleteKeyPair
* ec2:CreateTags
* ec2:DescribeImages
* ec2:DescribeNetworkInterfaces
* ecs:DescribeClusters
* ecs:CreateCluster
* ecs:DeleteCluster
* autoscaling:DescribeLaunchConfigurations
* autoscaling:CreateLaunchConfiguration
* autoscaling:DeleteLaunchConfiguration
* autoscaling:DescribeScalingActivities
* autoscaling:DescribeAutoScalingGroups
* autoscaling:CreateAutoScalingGroup
* autoscaling:UpdateAutoScalingGroup
* autoscaling:DeleteAutoScalingGroup
* logs:CreateLogGroup
* logs:DescribeLogGroups
* logs:ListTagsLogGroup
* logs:DeleteLogGroup


Development
-----------

### Machine Requirements

In order for the build to run correctly, a few tools will need to be installed
on your development machine:

* Ruby (2.3.1)
* Bundler
* git
* git-crypt
* gnupg
* direnv

#### Mac OS X Setup

Installing the required tools is best managed by [homebrew](http://brew.sh).

To install homebrew:

```
ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
```

Then, to install the required tools:

```
# ruby
brew install rbenv
brew install ruby-build
echo 'eval "$(rbenv init - bash)"' >> ~/.bash_profile
echo 'eval "$(rbenv init - zsh)"' >> ~/.zshrc
eval "$(rbenv init -)"
rbenv install 2.3.1
rbenv rehash
rbenv local 2.3.1
gem install bundler

# git, git-crypt, gnupg
brew install git
brew install git-crypt
brew install gnupg

# direnv
brew install direnv
echo "$(direnv hook bash)" >> ~/.bash_profile
echo "$(direnv hook zsh)" >> ~/.zshrc
eval "$(direnv hook $SHELL)"

direnv allow <repository-directory>
```

### Running the build

To provision module infrastructure, run tests and then destroy that
infrastructure, execute:

```bash
./go
```

To provision the module prerequisites:

```bash
./go deployment:prerequisites:provision[<deployment_identifier>]
```

To provision the module contents:

```bash
./go deployment:harness:provision[<deployment_identifier>]
```

To destroy the module contents:

```bash
./go deployment:harness:destroy[<deployment_identifier>]
```

To destroy the module prerequisites:

```bash
./go deployment:prerequisites:destroy[<deployment_identifier>]
```


### Common Tasks

#### Generating an SSH key pair

To generate an SSH key pair:

```
ssh-keygen -t rsa -b 4096 -C integration-test@example.com -N '' -f config/secrets/keys/bastion/ssh
```

#### Managing CircleCI keys

To encrypt a GPG key for use by CircleCI:

```bash
openssl aes-256-cbc \
  -e \
  -md sha1 \
  -in ./config/secrets/ci/gpg.private \
  -out ./.circleci/gpg.private.enc \
  -k "<passphrase>"
```

To check decryption is working correctly:

```bash
openssl aes-256-cbc \
  -d \
  -md sha1 \
  -in ./.circleci/gpg.private.enc \
  -k "<passphrase>"
```

Contributing
------------

Bug reports and pull requests are welcome on GitHub at
https://github.com/infrablocks/terraform-aws-ecs-cluster. This project is
intended to be a safe, welcoming space for collaboration, and contributors are
expected to adhere to the
[Contributor Covenant](http://contributor-covenant.org) code of conduct.


License
-------

The library is available as open source under the terms of the
[MIT License](http://opensource.org/licenses/MIT).

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 4.31.0 |
| <a name="provider_null"></a> [null](#provider\_null) | 3.1.1 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_autoscaling_group.cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group) | resource |
| [aws_cloudwatch_log_group.cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_ecs_capacity_provider.autoscaling_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_capacity_provider) | resource |
| [aws_ecs_cluster.cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_cluster) | resource |
| [aws_ecs_cluster_capacity_providers.capacity_providers](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_cluster_capacity_providers) | resource |
| [aws_iam_instance_profile.cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_policy.cluster_instance_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.cluster_service_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy_attachment.cluster_instance_policy_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy_attachment) | resource |
| [aws_iam_policy_attachment.cluster_service_policy_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy_attachment) | resource |
| [aws_iam_role.cluster_instance_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.cluster_service_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.task_execution_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.task_execution_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_key_pair.cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/key_pair) | resource |
| [aws_launch_configuration.cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_configuration) | resource |
| [aws_security_group.cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group_rule.cluster_default_egress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.cluster_default_ingress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [null_resource.iam_wait](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [aws_ami.amazon_linux_2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_iam_policy_document.task_execution_assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.task_execution_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_allowed_cidrs"></a> [allowed\_cidrs](#input\_allowed\_cidrs) | The CIDRs allowed access to containers. | `list(string)` | <pre>[<br>  "10.0.0.0/8"<br>]</pre> | no |
| <a name="input_asg_capacity_provider_manage_scaling"></a> [asg\_capacity\_provider\_manage\_scaling](#input\_asg\_capacity\_provider\_manage\_scaling) | Whether or not to allow ECS to manage scaling for the ASG capacity provider ("yes" or "no"). | `string` | `"yes"` | no |
| <a name="input_asg_capacity_provider_manage_termination_protection"></a> [asg\_capacity\_provider\_manage\_termination\_protection](#input\_asg\_capacity\_provider\_manage\_termination\_protection) | Whether or not to allow ECS to manage termination protection for the ASG capacity provider ("yes" or "no"). | `string` | `"yes"` | no |
| <a name="input_asg_capacity_provider_maximum_scaling_step_size"></a> [asg\_capacity\_provider\_maximum\_scaling\_step\_size](#input\_asg\_capacity\_provider\_maximum\_scaling\_step\_size) | The maximum scaling step size for ECS managed scaling of the ASG capacity provider. | `number` | `1000` | no |
| <a name="input_asg_capacity_provider_minimum_scaling_step_size"></a> [asg\_capacity\_provider\_minimum\_scaling\_step\_size](#input\_asg\_capacity\_provider\_minimum\_scaling\_step\_size) | The minimum scaling step size for ECS managed scaling of the ASG capacity provider. | `number` | `1` | no |
| <a name="input_asg_capacity_provider_target_capacity"></a> [asg\_capacity\_provider\_target\_capacity](#input\_asg\_capacity\_provider\_target\_capacity) | The target capacity, as a percentage from 1 to 100, for the ASG capacity provider. | `number` | `100` | no |
| <a name="input_associate_public_ip_addresses"></a> [associate\_public\_ip\_addresses](#input\_associate\_public\_ip\_addresses) | Whether or not to associate public IP addresses with ECS container instances ("yes" or "no"). | `string` | `"no"` | no |
| <a name="input_cluster_desired_capacity"></a> [cluster\_desired\_capacity](#input\_cluster\_desired\_capacity) | The desired capacity of the ECS cluster. | `string` | `3` | no |
| <a name="input_cluster_instance_amis"></a> [cluster\_instance\_amis](#input\_cluster\_instance\_amis) | A map of regions to AMIs for the container instances. | `map(string)` | <pre>{<br>  "af-south-1": "",<br>  "ap-east-1": "",<br>  "ap-northeast-1": "",<br>  "ap-northeast-2": "",<br>  "ap-northeast-3": "",<br>  "ap-south-1": "",<br>  "ap-southeast-1": "",<br>  "ap-southeast-2": "",<br>  "ca-central-1": "",<br>  "cn-north-1": "",<br>  "cn-northwest-1": "",<br>  "eu-central-1": "",<br>  "eu-north-1": "",<br>  "eu-south-1": "",<br>  "eu-west-1": "",<br>  "eu-west-2": "",<br>  "eu-west-3": "",<br>  "me-south-1": "",<br>  "sa-east-1": "",<br>  "us-east-1": "",<br>  "us-east-2": "",<br>  "us-west-1": "",<br>  "us-west-2": ""<br>}</pre> | no |
| <a name="input_cluster_instance_iam_policy_contents"></a> [cluster\_instance\_iam\_policy\_contents](#input\_cluster\_instance\_iam\_policy\_contents) | The contents of the cluster instance IAM policy. | `string` | `""` | no |
| <a name="input_cluster_instance_root_block_device_size"></a> [cluster\_instance\_root\_block\_device\_size](#input\_cluster\_instance\_root\_block\_device\_size) | The size in GB of the root block device on cluster instances. | `number` | `30` | no |
| <a name="input_cluster_instance_root_block_device_type"></a> [cluster\_instance\_root\_block\_device\_type](#input\_cluster\_instance\_root\_block\_device\_type) | The type of the root block device on cluster instances ('standard', 'gp2', or 'io1'). | `string` | `"standard"` | no |
| <a name="input_cluster_instance_ssh_public_key_path"></a> [cluster\_instance\_ssh\_public\_key\_path](#input\_cluster\_instance\_ssh\_public\_key\_path) | The path to the public key to use for the container instances. | `string` | `""` | no |
| <a name="input_cluster_instance_type"></a> [cluster\_instance\_type](#input\_cluster\_instance\_type) | The instance type of the container instances. | `string` | `"t2.medium"` | no |
| <a name="input_cluster_instance_user_data_template"></a> [cluster\_instance\_user\_data\_template](#input\_cluster\_instance\_user\_data\_template) | The contents of a template for container instance user data. | `string` | `""` | no |
| <a name="input_cluster_maximum_size"></a> [cluster\_maximum\_size](#input\_cluster\_maximum\_size) | The maximum size of the ECS cluster. | `string` | `10` | no |
| <a name="input_cluster_minimum_size"></a> [cluster\_minimum\_size](#input\_cluster\_minimum\_size) | The minimum size of the ECS cluster. | `string` | `1` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | The name of the cluster to create. | `string` | `"default"` | no |
| <a name="input_cluster_service_iam_policy_contents"></a> [cluster\_service\_iam\_policy\_contents](#input\_cluster\_service\_iam\_policy\_contents) | The contents of the cluster service IAM policy. | `string` | `""` | no |
| <a name="input_component"></a> [component](#input\_component) | The component this cluster will contain. | `string` | n/a | yes |
| <a name="input_cw_log_retention_in_days"></a> [cw\_log\_retention\_in\_days](#input\_cw\_log\_retention\_in\_days) | Cloudwatch Log retention in days | `number` | `3` | no |
| <a name="input_deployment_identifier"></a> [deployment\_identifier](#input\_deployment\_identifier) | An identifier for this instantiation. | `string` | n/a | yes |
| <a name="input_egress_cidrs"></a> [egress\_cidrs](#input\_egress\_cidrs) | The CIDRs accessible from containers. | `list(string)` | <pre>[<br>  "0.0.0.0/0"<br>]</pre> | no |
| <a name="input_enable_container_insights"></a> [enable\_container\_insights](#input\_enable\_container\_insights) | Whether or not to enable container insights on the ECS cluster ("yes" or "no"). | `string` | `"no"` | no |
| <a name="input_include_asg_capacity_provider"></a> [include\_asg\_capacity\_provider](#input\_include\_asg\_capacity\_provider) | Whether or not to add the created ASG as a capacity provider for the ECS cluster ("yes" or "no"). | `string` | `"no"` | no |
| <a name="input_include_default_egress_rule"></a> [include\_default\_egress\_rule](#input\_include\_default\_egress\_rule) | Whether or not to include the default egress rule on the ECS container instances security group ("yes" or "no"). | `string` | `"yes"` | no |
| <a name="input_include_default_ingress_rule"></a> [include\_default\_ingress\_rule](#input\_include\_default\_ingress\_rule) | Whether or not to include the default ingress rule on the ECS container instances security group ("yes" or "no"). | `string` | `"yes"` | no |
| <a name="input_protect_cluster_instances_from_scale_in"></a> [protect\_cluster\_instances\_from\_scale\_in](#input\_protect\_cluster\_instances\_from\_scale\_in) | Whether or not to protect cluster instances in the autoscaling group from scale in ("yes" or "no"). | `string` | `"no"` | no |
| <a name="input_region"></a> [region](#input\_region) | The region into which to deploy the cluster. | `string` | n/a | yes |
| <a name="input_security_groups"></a> [security\_groups](#input\_security\_groups) | The list of security group IDs to associate with the cluster. | `list(string)` | `[]` | no |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | The IDs of the subnets for container instances. | `list(string)` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Map of tags to be applied to all resources in cluster | `map(string)` | `{}` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | The ID of the VPC into which to deploy the cluster. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_asg_capacity_provider_name"></a> [asg\_capacity\_provider\_name](#output\_asg\_capacity\_provider\_name) | The name of the ASG capacity provider associated with the cluster. |
| <a name="output_autoscaling_group_arn"></a> [autoscaling\_group\_arn](#output\_autoscaling\_group\_arn) | The ARN of the autoscaling group for the ECS container instances. |
| <a name="output_autoscaling_group_name"></a> [autoscaling\_group\_name](#output\_autoscaling\_group\_name) | The name of the autoscaling group for the ECS container instances. |
| <a name="output_capacity_provider_name"></a> [capacity\_provider\_name](#output\_capacity\_provider\_name) | The name of the capacity provider. |
| <a name="output_cluster_arn"></a> [cluster\_arn](#output\_cluster\_arn) | The ARN of the created ECS cluster. |
| <a name="output_cluster_id"></a> [cluster\_id](#output\_cluster\_id) | The ID of the created ECS cluster. |
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | The name of the created ECS cluster. |
| <a name="output_instance_policy_arn"></a> [instance\_policy\_arn](#output\_instance\_policy\_arn) | The ARN of the container instance policy. |
| <a name="output_instance_policy_id"></a> [instance\_policy\_id](#output\_instance\_policy\_id) | The ID of the container instance policy. |
| <a name="output_instance_role_arn"></a> [instance\_role\_arn](#output\_instance\_role\_arn) | The ARN of the container instance role. |
| <a name="output_instance_role_id"></a> [instance\_role\_id](#output\_instance\_role\_id) | The ID of the container instance role. |
| <a name="output_launch_configuration_name"></a> [launch\_configuration\_name](#output\_launch\_configuration\_name) | The name of the launch configuration for the ECS container instances. |
| <a name="output_log_group"></a> [log\_group](#output\_log\_group) | The name of the default log group for the cluster. |
| <a name="output_security_group_id"></a> [security\_group\_id](#output\_security\_group\_id) | The ID of the default security group associated with the ECS container instances. |
| <a name="output_service_policy_arn"></a> [service\_policy\_arn](#output\_service\_policy\_arn) | The ARN of the ECS service policy. |
| <a name="output_service_policy_id"></a> [service\_policy\_id](#output\_service\_policy\_id) | The ID of the ECS service policy. |
| <a name="output_service_role_arn"></a> [service\_role\_arn](#output\_service\_role\_arn) | The ARN of the ECS service role. |
| <a name="output_service_role_id"></a> [service\_role\_id](#output\_service\_role\_id) | The ID of the ECS service role. |
| <a name="output_task_execution_role_arn"></a> [task\_execution\_role\_arn](#output\_task\_execution\_role\_arn) | The ARN of the container instance role. |
| <a name="output_task_execution_role_id"></a> [task\_execution\_role\_id](#output\_task\_execution\_role\_id) | The ID of the container instance role. |
| <a name="output_task_execution_role_name"></a> [task\_execution\_role\_name](#output\_task\_execution\_role\_name) | The ID of the container instance role. |
<!-- END_TF_DOCS -->