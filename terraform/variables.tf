variable "yc_iam_token" {
  description = "Токен для подключения с сервисной ролью к yandex cloud"
  type = string
  sensitive = true
}

variable "yc_cloud_id" {
  description = " ID облака yandex cloud"
  type = string
  sensitive = true
}

variable "yc_folder_id" {
  description = "ID рабочего проекта yandex cloud"
  type = string
  sensitive = true
}

variable "yc_vm_ssh_key" {
  description = "Открытая часть ssh ключа для подключения к виртуальным машинам"
  type = string
  sensitive = true
}

variable "yc_domain" {
  description = "Домен сайта"
  type        = string
  sensitive   = true
}

variable "yc_zone" {
  description = "Дефолтная зона доступности"
  type = string
  default = "ru-central1-a"
}

variable "yc_storage_access_key" {
  description = "Ключ доступа Yandex Cloud Storage"
  type        = string
  sensitive   = true
}

variable "yc_storage_secret_key" {
  description = "Секретный ключ Yandex Cloud Storage"
  type        = string
  sensitive   = true
}

variable "terraform-state-backed" {
  description = "Название бакета"
  type        = string
  default = "terraform-state-backed"
}
