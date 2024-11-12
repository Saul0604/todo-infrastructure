provider "digitalocean"{
    token = var.DO_TOKEN
}

terraform{
    required_providers {
      digitalocean = {
        source = "digitalocean/digitalocean"
        version = "~> 2.0"
      }
    }

    backend "s3"{
        endpoints = {
            s3 = "https://nyc3.digitaloceanspaces.com"
        }
        bucket = "dev-saulapp"
        key = "terraform.tfstate"
        skip_credentials_validation = true
        skip_metadata_api_check = true
        skip_requesting_account_id = true
        skip_s3_checksum = true
        region = "us-east-1"
    }
    
}

resource "digitalocean_project" "saul_server_project"{
    name = "saul_server_project"
    description = "servidor para cositas personales"
    resources = [digitalocean_droplet.saul_server_droplet.urn]
}

resource "digitalocean_ssh_key" "saul_server_ssh_key"{
    name = "saul_server_key"
    public_key = file("./keys/saul_server.pub")
}

resource "digitalocean_droplet" "saul_server_droplet"{
    name = "daulserver"
    size = "s-2vcpu-4gb-120gb-intel"
    image = "ubuntu-24-04-x64"
    region = "sfo3"
    ssh_keys =  [digitalocean_ssh_key.saul_server_ssh_key.id]
    user_data = file("./docker-install.sh")

    provisioner "remote-exec" {
        inline = [ 
            "mkdir -p /proyects",
            "touch /proyects/.env",
            "echo \"MYSQL_DB=${var.MYSQL_DB}\" >> /proyects/.env",
            "echo \"MYSQL_USER=${var.MYSQL_USER}\" >> /proyects/.env",
            "echo \"MYSQL_HOST=${var.MYSQL_HOST}\" >> /proyects/.env",
            "echo \"MYSQL_PASSWORD=${var.MYSQL_PASSWORD}\" >> /proyects/.env"
         ]
         connection{
                type = "ssh"
                user = "root"
                private_key = file("./keys/saul_server")
                host = self.ipv4_address
         }
    }
    
    provisioner "file" {

        source = "./Containers/docker-compose.yml"
        destination = "/proyects/docker-compose.yml"

        connection{
                type = "ssh"
                user = "root"
                private_key = file("./keys/saul_server")
                host = self.ipv4_address
         }
    }
     
    
}

# resource "time_sleep" "wait_docker_install" {
#     depends_on = [ digitalocean_droplet.saul_server_droplet ]
#     create_duration = "130s"
# }

# resource "null_resource" "init_api" {
#     depends_on = [ time_sleep.wait_docker_install ]
#   provisioner "remote-exec" {
#         inline = [ 
#             "cd /proyects",
#             "docker-compose up -d",
#          ]

#          connection {
#            type = "ssh"
#            user = "root"
#            private_key = file("./keys/saul_server")
#            host = digitalocean_droplet.saul_server_droplet.ipv4_address
#          }
#   }
# }

# # resource "null_resource" "init_nginx" {
# #     depends_on = [ time_sleep.wait_docker_install ]
# #     connection {
# #         type = "ssh"
# #         user = "root"
# #         private_key = file("./keys/pipe_server_new")
# #         host = digitalocean_droplet.pipe_server_droplet.ipv4_address
# #     }

# #     provisioner "remote-exec" {
# #       inline = [ "docker container run --name=Adidas -dp 80:80 nginx" ]
# #     }
# # }
# # #Copiar carpeta adidas a servidor 
# # resource "null_resource" "adidas_copy" {
# #     provisioner "file" {
# #       source = "./Proyecto_Clon_Adiddas"
# #       destination = "/adidas"
# #     }
# #     connection {
# #         type = "ssh"
# #         user = "root"
# #         private_key = file("./keys/pipe_server_new")
# #         host = digitalocean_droplet.pipe_server_droplet.ipv4_address 
# #     }
# # }
# # # 1.- Hacer "cd /"
# # # 2.- Hacer "docker cp adidas/. Adidas:/usr/share/nginx/html"

# # resource "null_resource" "copy_to_nginx_container" {
# #     depends_on = [ null_resource.adidas_copy, null_resource.init_nginx ]
# #     connection {
# #         type = "ssh"
# #         user = "root"
# #         private_key = file("./keys/pipe_server_new")
# #         host = digitalocean_droplet.pipe_server_droplet.ipv4_address 
# #     }
# #     provisioner "remote-exec" {
# #       inline = [ 
# #         "cd /", 
# #         "docker cp adidas/. Adidas:/usr/share/nginx/html"]
# #     }
    
# # }

output "ip"{
    value = digitalocean_droplet.saul_server_droplet.ipv4_address
}


