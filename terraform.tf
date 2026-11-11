terraform {

  required_version = "~> 1.12"

  backend "s3" {
    bucket       = "milanoid-labs-terraform-tofu-state"
    key          = "milanoid-hetzner-terraform/terraform.tfstate"
    use_lockfile = true
    region       = "eu-central-1"
    # Locally: direnv (.envrc) sets AWS_PROFILE=milanoid.
    encrypt = true # to make it explicit, S3 default encryption is enabled in AWS
  }

  required_providers {
    hcloud = {
      # Storage Box resources (hcloud_storage_box, hcloud_storage_box_subaccount) are
      # recent additions to the provider; older minors don't have them.
      source  = "hetznercloud/hcloud"
      version = "~> 1.70.2"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.9.1"
    }
  }
}

# The token comes from the HCLOUD_TOKEN environment variable (CI: repo secret HCLOUD_TOKEN;
# locally: ~/.config/milanoid-hetzner-terraform.env via direnv). Project: milanoid-backup.
provider "hcloud" {}
