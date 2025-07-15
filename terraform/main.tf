# Настройки сети
resource "yandex_vpc_network" "app_network" {
  name = "app_network"
  description = "Виртульную сеть для приложения"
}

resource "yandex_vpc_subnet" "app_subnet" {
  name = "app_subnet"
  description = "Подсеть"
  v4_cidr_blocks = ["10.2.0.0/24"]
  zone = var.yc_zone
  network_id = yandex_vpc_network.app_network.id
}


# Настройки групп беапасности
resource "yandex_vpc_security_group" "lb-sg" {
  name = "load-balancer-security-group"
  description = "Группа безопасности для балансировщика нагрузки"
  network_id = yandex_vpc_network.app_network.id

  ingress {
    description    = "Трафик по http"
    protocol       = "TCP"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description    = "Трафик по https"
    protocol       = "TCP"
    port           = 443
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    description       = "Проверка состояния балансера"
    protocol          = "TCP"
    port              = 30080
    predefined_target = "loadbalancer_healthchecks"
  }

  egress {
    description    = "Разрешен весь исходящий трафик"
    protocol       = "ANY"
    from_port      = 0
    to_port        = 65535
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group" "vm-sg" {
  name = "vm-security-group"
  description = "Группа безопасности для виртуальных машин"
  network_id = yandex_vpc_network.app_network.id

  ingress {
    description = "Доступ разрешен из группы лоад балансера по http"
    protocol       = "TCP"
    port           = 80
    security_group_id = yandex_vpc_security_group.lb-sg.id
  }

  ingress {
    description = "Доступ разрешен из группы лоад балансера по https"
    protocol       = "TCP"
    port           = 443
    security_group_id = yandex_vpc_security_group.lb-sg.id
  }
  
  ingress {
    protocol       = "TCP"
    port           = 3000
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Для подключения по ssh"
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description    = "Разрешен весь исходящий трафик"
    protocol       = "ANY"
    from_port      = 0
    to_port        = 65535
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# Настройка виртуальных машин

resource "yandex_compute_instance" "app_server" {
  description = "Создаем 2 виртуальные машины"
  name        = "app-server-${count.index + 1}"
  count       = 2
  platform_id = "standard-v1"
  zone        = var.yc_zone

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      description = "Ubuntu 22.04 LTS"
      image_id = "fd8jfh73rvks3qlqp3ck"
      size     = 10
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.app_subnet.id
    security_group_ids = [yandex_vpc_security_group.vm-sg.id]
    nat                = true
  }

  metadata = {
    ssh-keys = "dobby:${var.yc_vm_ssh_key}"
  }
}

# Настройка балансировщика нагрузки

# HTTP-роутер
resource "yandex_alb_http_router" "app-http-router" {
  name = "app-http-router"
  folder_id = var.yc_folder_id
}

resource "yandex_alb_virtual_host" "app_virtual_host" {
  name           = "app-virtual-host"
  http_router_id = yandex_alb_http_router.app-http-router.id
  authority = [var.yc_domain]

  route {
    name = "main-https-route"
    http_route {
      http_route_action {
        backend_group_id = yandex_alb_backend_group.app_backend_group.id
        timeout          = "60s"
      }
    }
  }
}

resource "yandex_alb_target_group" "app_target_group" {
  name = "app-target-group"
  folder_id = var.yc_folder_id
  description = "Целевая группа для виртуальны машин"

  dynamic "target" {
     for_each = yandex_compute_instance.app_server
     content {
       subnet_id  = yandex_vpc_subnet.app_subnet.id
       ip_address = target.value.network_interface.0.ip_address
     }
   }
}

resource "yandex_alb_backend_group" "app_backend_group" {
  name = "app-backend-group"
  folder_id = var.yc_folder_id
  description = "Бекенд группа для балансировщика"

  http_backend {
    name             = "app-backend"
    weight           = 1
    port             = 3000
    target_group_ids = [yandex_alb_target_group.app_target_group.id]
  load_balancing_config {
   mode = "ROUND_ROBIN"
  }
  }
}

resource "yandex_cm_certificate" "app_cert" {
  name        = "app-certificate"
  description = "Сертификат для домена"
  domains     = [var.yc_domain]

  managed {
    challenge_type = "DNS_CNAME"
  }
}

resource "yandex_vpc_address" "alb_ip" {
  name = "load-balancer-ip"
  
  external_ipv4_address {
    zone_id = var.yc_zone
  }
}

resource "yandex_alb_load_balancer" "app-lb" {
  name = "app-lb"
  description = "Балансер уровня приложения"
  network_id = yandex_vpc_network.app_network.id
  folder_id = var.yc_folder_id
  security_group_ids = [yandex_vpc_security_group.lb-sg.id]


  allocation_policy {
    location {
      zone_id = var.yc_zone
      subnet_id = yandex_vpc_subnet.app_subnet.id
    }
  }

  listener {
      name = "http-listener"
      endpoint {
        address {
          external_ipv4_address {
            address = yandex_vpc_address.alb_ip.external_ipv4_address[0].address
          }
        }
        ports = [80]
      }
      http {
        redirects {
          http_to_https = true
        }
      }
    }

  listener {
    name = "https-listener"
    endpoint {
      address {
        external_ipv4_address {
          address = yandex_vpc_address.alb_ip.external_ipv4_address[0].address
        }
      }
      ports = [443]
    }
    tls {
      default_handler {
        certificate_ids = [yandex_cm_certificate.app_cert.id]
        http_handler {
          http_router_id = yandex_alb_http_router.app-http-router.id
        }
      }
    }
  }
}

# Делегирование домена

resource "yandex_dns_zone" "app_zone" {
  name        = "app-zone"
  description = "Создание DNS зоны для приложения"
  zone        = format("%s.", var.yc_domain)
  public      = true
}

# Создание ресурсных записей

resource "yandex_dns_recordset" "rs-a" {
  zone_id = yandex_dns_zone.app_zone.id
  name    = var.yc_domain
  type    = "A"
  ttl     = 600
  data    = [yandex_alb_load_balancer.app-lb.listener[0].endpoint[0].address[0].external_ipv4_address[0].address]
}

resource "yandex_dns_recordset" "cert_cname" {
  zone_id = yandex_dns_zone.app_zone.id
  name    = "_acme-challenge.${var.yc_domain}."
  type    = "CNAME"
  ttl     = 600
  data    = [one([
      for challenge in yandex_cm_certificate.app_cert.challenges :
      challenge.dns_value
      if challenge.type == "DNS" && challenge.dns_value != ""
    ])]
}

# Создание файла инвентаризации для Ansible

resource "local_file" "ansible_inventory" {
  filename = "../ansible/inventory.ini"
  content = templatefile("inventory.tftpl",
    {
      web_servers_ips = {
        for instance in yandex_compute_instance.app_server :
        instance.name => instance.network_interface.0.nat_ip_address
      }
    })
}

# Монитор доступности сервера
resource "datadog_monitor" "web_server_status" {
  name    = "[Web] Server Status - {{host.name}}"
  type    = "service check"
  query   = "\"datadog.agent.up\".over(\"env:production\",\"service:redmine\").by(\"host\").last(2).count_by_status()"
  message = "Web server {{host.name}} is down!"

  monitor_thresholds {
    critical = 1
    warning  = 1
  }
  
  notify_no_data    = true
  no_data_timeframe = 10
  renotify_interval = 0
}

# Монитор нагрузки CPU
resource "datadog_monitor" "web_cpu_usage" {
  name    = "[Web] High CPU Usage - {{host.name}}"
  type    = "metric alert"
  query   = "avg(last_5m):avg:system.cpu.user{env:production,service:redmine} by {host} > 80"
  message = "High CPU usage detected on {{host.name}}"

  monitor_thresholds {
    critical = 80
    warning  = 70
  }
  
  notify_no_data    = true
  no_data_timeframe = 10
}
