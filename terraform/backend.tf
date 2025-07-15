# terraform {
#   backend "s3" {
#     endpoint   = "https://storage.yandexcloud.net"
#     bucket     = var.terraform-state-backed
#     region     = var.yc_zone
#     key        = "terraform.tfstate"
#     access_key = var.yc_storage_access_key
#     secret_key = var.yc_storage_secret_key

#     skip_region_validation      = true
#     skip_credentials_validation = true
#     skip_requesting_account_id  = true
#     skip_s3_checksum            = true
#   }
# }