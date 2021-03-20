## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.12 |

## Providers

| Name | Version |
|------|---------|
| aws | n/a |

## Modules

No Modules.

## Resources

| Name |
|------|
| [aws_acm_certificate](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate) |
| [aws_acm_certificate_validation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate_validation) |
| [aws_alb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/alb) |
| [aws_alb_listener](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/alb_listener) |
| [aws_alb_target_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/alb_target_group) |
| [aws_availability_zones](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) |
| [aws_db_instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance) |
| [aws_db_subnet_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_subnet_group) |
| [aws_ecs_cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_cluster) |
| [aws_ecs_service](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service) |
| [aws_ecs_task_definition](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition) |
| [aws_iam_policy_document](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) |
| [aws_iam_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) |
| [aws_internet_gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway) |
| [aws_route](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) |
| [aws_route53_record](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) |
| [aws_route53_zone](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) |
| [aws_security_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) |
| [aws_subnet](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) |
| [aws_vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| appsilon\_subdomain | The Subdomain for your service. | `string` | `"rshiny-demo"` | no |
| appsilon\_version\_tag | Docker image tag of the application. | `string` | `"v1.0.0"` | no |
| az\_count | How many AZ's to create in the VPC | `number` | `2` | no |
| domain | Domain name. Service will be deployed using the appsilon\_subdomain | `any` | n/a | yes |
| ecs\_cluster\_name | The name to assign to the ECS cluster | `string` | `"appsilon-cluster"` | no |
| environment | Environment variables for ECS task: [ { name = "foo", value = "bar" }, ..] | `list` | `[]` | no |
| rds\_db\_name | The DB name in the RDS instance | `any` | n/a | yes |
| rds\_instance | The size of RDS instance, eg db.t2.micro | `any` | n/a | yes |
| rds\_password | The password for RDS | `any` | n/a | yes |
| rds\_storage\_encrypted | Whether the data on the PostgreSQL instance should be encrpyted. | `bool` | `false` | no |
| rds\_username | The username for RDS | `any` | n/a | yes |
| region | Region to deploy | `string` | `"eu-west-2"` | no |

## Outputs

| Name | Description |
|------|-------------|
| ecs\_security\_group | Security group controlling access to the ECS tasks |
| private\_subnets | Private subnets created for RDS within the VPC, each in a different AZ |
| public\_subnets | Public subnets created for appsilon within the VPC, each in a different AZ |
| vpc | VPC created to hold appsilon resources |
