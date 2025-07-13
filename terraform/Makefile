#  Создание сертификата lets encript
tf-cert:
	terraform apply -target=yandex_cm_certificate.app_cert -target=yandex_dns_zone.app_zone

# Добавление CNAME записи для проверки сертификата
tf-add-cname:
	terraform apply -target=yandex_dns_recordset.cert_cname

# Создание S3 бакета для хранения состояния
tf-add-s3:
	terraform apply -target=yandex_storage_bucket.terraform_state

tf-init:
	terraform init

tf-deploy:
	terraform apply

tf-destroy:
	terraform destroy