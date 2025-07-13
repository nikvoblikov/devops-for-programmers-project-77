# Установить необходимые роли и коллекции
ansible-pre-install:
	ansible-galaxy install -r ./ansible/requirements.yml

# Подготовка целевых машин
ansible-prepare-servers:
	ansible-playbook -i ./ansible/inventory.ini ./ansible/playbook.yml -t prepare-servers

# Создать vault.yml файл
vault:
	cp -n ./ansible/group_vars/webservers/vault.example ./ansible/group_vars/webservers/vault.yml || true
	@echo "✅ vault.yml checked (created if not exists)"

# Зашифровать файл vault.yml
ansible-vault-encrypt:
	ansible-vault encrypt ./ansible/group_vars/webservers/vault.yml

# Деплой приложения
ansible-deploy:
	ansible-playbook -i ./ansible/inventory.ini ./ansible/playbook.yml -t install-redmine --ask-vault-pass

# Добавление мониторинга
ansible-monitoring:
	ansible-playbook -i ./ansible/inventory.ini ./ansible/playbook.yml -t monitoring --ask-vault-pass 

# Создать сертификат
inf-add-cert:
	make -C terraform tf-cert

# Проверить сертификат
inf-validate-cert:
	make -C terraform tf-add-cname

# Создать бакет для состояния
inf-add-s3:
	make -C terraform tf-add-s3
	
# Создать инфраструктуру
inf-deploy:
	make -C terraform tf-init
	make -C terraform tf-apply

# Откатить инфраструктуру
inf-destroy:
	make -C terraform tf-destroy