### Hexlet tests and linter status:
[![Actions Status](https://github.com/nikvoblikov/devops-for-programmers-project-76/actions/workflows/hexlet-check.yml/badge.svg)](https://github.com/nikvoblikov/devops-for-programmers-project-76/actions)

## Перед началом работы

Установите необходимы роли и коллекции:
```bash
make pre-install
```

Мы предполагаем деплой на yandex cloud. Подготовьте всю инфрастукруту на стороне облака. Подключитесь к своим виртуальным машинам по ssh.

После чего подготовьте их, запустив команду:
```bash
make prepare-servers
```
При этом на целевых ВМ установится докер, запустится его демон, создаться необходимый юзер.

## Деплой приложения Redmine на удаленный сервер

Создайте `vault.yml` файл из шаблона, запустив команду:
```bash
make vault
```

Внесите необходимые переменные для подключения к своей базе данных. Для проекта я выбрал базу [MySql](https://yandex.cloud/ru/docs/managed-mysql/)

Пример заполнения:
```
REDMINE_DB_USERNAME: redmine
REDMINE_DB_PASSWORD: redmine
REDMINE_DB_MYSQL: <host-name>.mdb.yandexcloud.net
REDMINE_DB_DATABASE: db1
```

После чего зашифруйте файл `vault.yml` с паролем:
```bash
make vault-encrypt
```

Теперь можно задеплоить приложение:
```bash
make deploy
```

Во время деплоя на целевых машинах запуститься докер образ Redmine, произойдет его подключение к базе данных `MySql`, накатятся необходимые миграции.

Проверьте состояние виртуальных машин и балансировщика нагрузки.

Приложение можно посмотреть по адресу [repositorium.shop](https://repositorium.shop/)

## Добавление мониторинга Datadog

Зарегестрируйтесь на Datadog, получите ключ api и добавьте его в `vault.yml`.
После чего запустите команду:
```bash
make monitoring
```

## Документация Yandex cloud

- [Yandex Compute Cloud](https://yandex.cloud/ru/docs/compute)
- [Yandex Application Load Balancer](https://yandex.cloud/ru/docs/application-load-balancer)
- [Yandex Virtual Private Cloud](https://yandex.cloud/ru/docs/vpc)
- [Yandex Managed Service for MySQL](https://yandex.cloud/ru/docs/managed-mysql)