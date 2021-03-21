## Requirements

No requirements.

## Providers

No provider.

## Modules

| Name | Source | Version |
|------|--------|---------|
| terraform-aws-appsilon | ./modules/terraform-aws-appsilon |  |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| appsilon\_subdomain | The Subdomain for your appsilon service. | `string` | `"appsilon"` | no |
| appsilon\_version\_tag | The Docker image tag version. | `any` | n/a | yes |
| az\_count | How many AZ's to create in the VPC | `number` | `2` | no |
| domain | Domain name. Service will be deployed using the appsilon\_subdomain | `any` | n/a | yes |
| ecs\_cluster\_name | The name to assign to the ECS cluster | `string` | `"appsilon-cluster"` | no |
| environment | Environment variables for ECS task: [ { name = "foo", value = "bar" }, ..] | `list` | `[]` | no |
| rds\_db\_name | The DB name in the RDS instance | `any` | n/a | yes |
| rds\_instance | The size of RDS instance, eg db.t2.micro | `any` | n/a | yes |
| rds\_password | The password for RDS | `any` | n/a | yes |
| rds\_username | The username for RDS | `any` | n/a | yes |
| region | Region to deploy | `any` | n/a | yes |

## Outputs

No output.
