
provider "aws" {
  region                  = var.aws_pri_region
  shared_credentials_file = "myaws_cred"
  profile                 = "sk"
  alias                   = "SK_pri_region"
}

provider "aws" {
  region                  = var.aws_sec_region
  shared_credentials_file = "myaws_cred"
  profile                 = "sk"
  alias                   = "SK_sec_region"
}
