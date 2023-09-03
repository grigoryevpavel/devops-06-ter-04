terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">=0.13"
}

provider "yandex" {
  token     = var.token
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  zone      = var.default_zone
}



#создаем облачную сеть с подсетью

module "vpc_dev"{
  source="./modules/vpc_dev"
  zone=var.default_zone
  cidr_block=["10.0.1.0/24"]
  env_name  ="develop"
}

# создаем ВМ
module "test-vm" {
  source          = "git::https://github.com/udjin10/yandex_compute_instance.git?ref=main"
  env_name        = "develop"
  network_id      = module.vpc_dev.vpc_network.id
  subnet_zones    = [var.default_zone]
  subnet_ids      = [ module.vpc_dev.vpc_subnet.id ]
  instance_name   = "web"
  instance_count  = 2
  image_family    = "ubuntu-2004-lts"
  public_ip       = true
  
  metadata = {
      user-data          = data.template_file.cloudinit.rendered 
      serial-port-enable = 1
  }

}

#инициализация ВМ
data "template_file" "cloudinit" {
 template = file("./cloud-init.yml")
 vars={
     public_key=var.public_key
 }
}

