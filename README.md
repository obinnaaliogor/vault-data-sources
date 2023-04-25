USING VAULT TO DYNAMICALLY PROVISION AN ACCESS IN AWS:
  3 blocks are needed 2 resource blocks and a vault provider block.
1. Define a vault provider block. 
example:
provider "vault" {
  address = var.vault_addr
  token   = var.vault_token
}

OR

provider "vault" {
  # It is strongly recommended to configure this provider through the
  # environment variables described above, so that each user can have
  # separate credentials set in the environment.
  #
  # This will default to using $VAULT_ADDR
  # But can be set explicitly
  # address = "https://vault.example.net:8200"
}
NB:
  In most cases it is recommended to set them via the indicated environment variables 
  in order to keep credential information out of the configuration.

The Vault provider allows Terraform to read from, write to, and configure HashiCorp Vault.

Interacting with Vault from Terraform causes any secrets that you read and write to be persisted 
in both Terraform's state file and in any generated plan files. For any Terraform module that 
reads or writes Vault secrets, these files should be treated as sensitive and protected accordingly.


The provider configuration block accepts the following arguments. In most cases it is recommended
to set them via the indicated environment variables in order to keep credential information out of the configuration.

2. Create a vault_aws_secret_backend resource.
This will have access and secret access key which are passed as arguments, since theyre going to be used 
to authenticate vault to make an API calls to aws.

The vault_aws_secret_backend issues access keys to users/developers once it has a role added to it.
The policy can be an administrator policy/s3full access depending on the permission that will be assigned to the user/developer/DevOps engineer.

example: 
resource "vault_aws_secret_backend" "aws" {
  access_key = var.access_key
  secret_key = var.secret_key
  region     = "us-east-2"

  default_lease_ttl_seconds = "120" #Time to live, expiration period of the access that will be created by vault.
  max_lease_ttl_seconds     = "240"
}

3. Create a vault_aws_secret_backend_role,
Creates a role on an AWS Secret Backend for Vault. Roles are used to map credentials to the policies that generated them.

example:
#   resource "vault_aws_secret_backend" "aws" {
#   access_key = "AKIA....."
#   secret_key = "AWS secret key"
# }

resource "vault_aws_secret_backend_role" "role" {
  backend = vault_aws_secret_backend.aws.path
  name    = "deploy"
  credential_type = "iam_user"

  policy_document = <<EOT
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "iam:*",
      "Resource": "*"
    }
  ]
}
EOT
}

This resource is used to map the credential, the secret and access key to a policy.

Thats all that is needed...
Once these credentials are generated in vault, it can then be used to provision resources.

AUTOMATING THE VAULT CREDENTIAL PROCESS USING BASH SHELL SCRIPTING:

# 1. This block will authenticate vault with aws and creates a secret engine called "aws" in vault.
 resource "vault_aws_secret_backend" "aws" {
  access_key = "AKIA....." #Pass your access key here better in variables.
   secret_key = "SECRETKEYFROMAWS"  #Pass your secret key here better in variables.

  region     = "us-east-2"
  default_lease_ttl_seconds = "120"
  max_lease_ttl_seconds     = "240"
}

# 2. This block will crate a IAM user in aws and assigns him/her the below stated policy.
resource "vault_aws_secret_backend_role" "role" {
  backend = vault_aws_secret_backend.aws.path
  name    = "test"
   credential_type = "iam_user"
    policy_document = <<EOT
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "iam:*", "ec2:*"
      ],
      "Resource": "*"
    }
  ]
}
EOT
}


# 3. GETTING THE CREATED CREDENTIAL/SECRET FROM VAULT SECRET ENGINE...

# We will use vault_aws_access_credentials to read the secret in vault and with data block get the secret as shown below .
# # generally, these blocks would be in a different module

data "vault_aws_access_credentials" "creds" {
  backend = vault_aws_secret_backend.aws.path
  role    = vault_aws_secret_backend_role.role.name
}

# 4. The gotten credentail from datasource will then be passed in an aws provider block to 
# utilize in provisioning an infrastructure. 
provider "aws" {
  access_key = data.vault_aws_access_credentials.creds.access_key
  secret_key = data.vault_aws_access_credentials.creds.secret_key
  region = var.region
}

