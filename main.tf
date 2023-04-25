#Set up a vault provider block
provider "vault"{
  address = var.vault_addr
  token   = var.vault_token
}

#2. This block will authenticate vault with aws and creates 
#a secret engine called "aws" in vault.

resource "vault_aws_secret_backend" "aws" {
  access_key                = var.access_key #Pass your access key here better in variables.
  secret_key                = var.secret_key #Pass your secret key here better in variables.
  region                    = "us-east-2"
  default_lease_ttl_seconds = "120"
  max_lease_ttl_seconds     = "240"
}
# 3. This block will crate a IAM user in aws and assigns him/her the below stated policy.
resource "vault_aws_secret_backend_role" "role" {
  backend = vault_aws_secret_backend.aws.path
  name    = "ec2-admin-role" #role name could be ec2-role or anything
  credential_type = "iam_user"
    policy_document = <<EOF
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
EOF
}

# 4. GETTING THE CREATED CREDENTIAL/SECRET FROM VAULT SECRET ENGINE...

# We will use vault_aws_access_credentials to read the secret in vault and with data block get the secret as shown below .
# # generally, these blocks would be in a different module

data "vault_aws_access_credentials" "creds" {
  backend = vault_aws_secret_backend.aws.path
  role    = vault_aws_secret_backend_role.role.name
}

# 5. The gotten credentail from datasource will then be passed in an aws provider block to 
# utilize in provisioning an infrastructure.

provider "aws" {
  access_key = data.vault_aws_access_credentials.creds.access_key
  secret_key = data.vault_aws_access_credentials.creds.secret_key
  region     = var.region
}

#6 Provison a simple resources
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "Prod"
  }
}