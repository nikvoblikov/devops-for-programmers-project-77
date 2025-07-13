### Hexlet tests and linter status:
[![Actions Status](https://github.com/nikvoblikov/devops-for-programmers-project-77/actions/workflows/hexlet-check.yml/badge.svg)](https://github.com/nikvoblikov/devops-for-programmers-project-77/actions)

## О проекте

Данный проект позволяет автоматизировать процесс развёртывания и настройки инфраструктуры Redmine в Yandex Cloud, используя Terraform и Ansible.

### Структура проекта

#### **terraform/**
- Инфраструктура как код (IaC) для развёртывания в Yandex Cloud
- Создание виртуальных машин, сети, балансировщика нагрузки и других ресурсов

#### **ansible/**
Автоматизация настройки серверов:
- Установка Docker и зависимостей
- Деплой Redmine в контейнерах
- Интеграция с Datadog для мониторинга

#### **Makefile**
Команды для упрощённия управление жизненным циклом

## Перед началом работы с проектом

### Установка зависимостей
- Установите [Terraform](https://www.terraform.io/downloads.html)
- Установите [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)

### Изучите документацию Yandex cloud

- [Yandex Compute Cloud](https://yandex.cloud/ru/docs/compute)
- [Yandex Application Load Balancer](https://yandex.cloud/ru/docs/application-load-balancer)
- [Yandex Virtual Private Cloud](https://yandex.cloud/ru/docs/vpc)
- [Yandex Managed Service for MySQL](https://yandex.cloud/ru/docs/managed-mysql)

### Зарегестрируйте в [datadog](https://www.datadoghq.com/)

## Управление проектом через Makefile

### Подготовка окружения
| Команда | Описание |
|---------|----------|
| `make ansible-pre-install` | Установка необходимых Ansible ролей и коллекций из `ansible/requirements.yml` |
| `make vault` | Создание файла `vault.yml` (если не существует) на основе примера |
| `make ansible-vault-encrypt` | Шифрование файла `vault.yml` с помощью Ansible Vault |

### Работа с инфраструктурой
| Команда | Описание |
|---------|----------|
| `make inf-add-s3` | Создание S3 бакета для хранения состояния Terraform |
| `make inf-deploy` | Полное развертывание инфраструктуры (инициализация + применение) |
| `make inf-destroy` | Удаление всей созданной инфраструктуры |
| `make inf-add-cert` | Создание SSL сертификата |
| `make inf-validate-cert` | Проверка и добавление CNAME для сертификата |

### Развертывание приложения
| Команда | Описание |
|---------|----------|
| `make ansible-prepare-servers` | Базовая настройка серверов (Docker, зависимости) |
| `make ansible-deploy` | Деплой Redmine (требует ввода пароля от vault) |
| `make ansible-monitoring` | Установка и настройка мониторинга Datadog (требует ввода пароля от vault) |

## Рабочий процесс

1. Сначала создайте сертификат для лоад балансера и провалидируйте его. Это может занять некоторое время.
```bash
make inf-add-cert
```
```bash
make inf-validate-cert
```

Создайте бакет для удаленного хранения состояния terraform
```bash
make inf-add-s3
```

2. Разверните инфраструктуру:  
```bash
make inf-deploy
```
3. Затем подготовьте серверы и выполните деплой:
```bash
make ansible-prepare-servers
make ansible-deploy
```
4. Для мониторинга
```bash
make ansible-monitoring
```

Для очистки ресурсов
```bash
make inf-destroy
```