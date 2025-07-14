terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
    datadog = {
      source = "DataDog/datadog"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.5.2"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  zone      = var.yc_zone
  token = var.yc_iam_token
  cloud_id  = var.yc_cloud_id
  folder_id = var.yc_folder_id
}

provider "datadog" {
  api_key = var.datadog_api_key
  app_key = var.datadog_app_key
  api_url = "https://api.datadoghq.eu/"
}
