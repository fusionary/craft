# Craft Terraform Config

This is a baseline terraform configuration for the standard Fusionary Craft template.

## Local Setup

Download `secrets.auto.tfvars.json` and `terraform.conf` from [1Password](https://start.1password.com/open/i?a=MTLB22HPNFB5ZBMKUZGKBZLRNM&v=3hsew7lvahgzmfxykx4h23jjde&i=htzq5suc2yxd7n3kd4etdksf2i&h=fusionary.1password.com) to the environment folder and intialize terraform.

```bash
terraform init -backend-config terraform.conf
```

## Configuration

Do a find in the environment folder for `@todo:` and set the appropriate variables.

## Run Locally

Run a plan

```bash
terraform plan -out plan.tfstate
```

This will list all of the change to be applied.

It is recommended to use Terrateam to deploy the infrastructure. However, it is possible to manually run the apply using

```bash
terraform apply plan.tfstate
```

## Deployment

Deployment of infrastructure happens automatically via [Terrateam](https://terrateam.io). Terraform plans occur on push requests and applies run on merge.

## Additional Environments

To add additional environments, duplicate the the `prod` folder and rename with the new environment name. Just follow the [Configuration](#configuration) steps to set variables for the new environment.
