variable "count" {
  default = 2
}

variable "defaults" {
  default = {
    "image"         = "8154f279-9ee6-403d-a233-18b2e9471927"
    "network"       = "ddbbb3b7-df46-4034-b269-6b7dbb324a08"
    "public_subnet" = "f208281f-3081-47ae-bcad-b1bd3e667787"
    "lbaas_subnet"  = "423e08bb-59f2-42bb-bb3f-1279bc6cf736"
    "region"        = "amers1"
    "key_pair"      = "compass"
    "flavor"        = "3"
    "username"      = "cloud"
    "password"      = "WilyToad1!"
  }
}

variable "rundeck" {
  default = {
    "host"          = "rundeck-01-alpha.amers2.cis.trcloud"
    "username"      = "cloud"
    "password"      = "WilyToad1"
    "ressources"    = "/var/rundeck/projects/poc/etc/resources.yaml"
    "keys"          = "/var/lib/rundeck/var/storage/content/keys"
    "tags"          = "poc"
  }
}


variable "hostnames" {
  default = {
    "0"         = "compass-int-poc-worker-01"
    "0.region"  = "amers1"
    "0.zone"    = "a"
    "1"         = "compass-int-poc-worker-02"
    "1.region"  = "amers1"
    "1.zone"    = "b"
    "2"         = "compass-int-poc-worker-03"
    "2.region"  = "amers1"
    "2.zone"    = "a"
    "3"         = "compass-int-poc-worker-04"
    "3.region"  = "amers1"
    "3.zone"    = "b"
    "4"         = "compass-int-poc-worker-05"
    "4.region"  = "amers1"
    "4.zone"    = "a"
    "5"         = "compass-int-poc-worker-06"
    "5.region"  = "amers1"
    "5.zone"    = "b"
  }
}

variable "cda" {
  default = {
    "environment"           = "development"
    "component"             = "client"
    "component_version"     = "1.8.1"
    "new_stack_version"     = "0.6.3"
    "component_stack_name"  = "Compass_Monitoring_Client_Stack_Development"
    "server_type"           = "compass"
    "deployment_group_name" = "Compass_Monitoring_Client_Only_Development"
  }
}

resource "openstack_blockstorage_volume_v1" "block_storage_1" {
  count = "${var.count}"
  region = "${lookup(var.hostnames, "${count.index}.region")}"
  availability_zone = "${lookup(var.hostnames, "${count.index}.region")}${lookup(var.hostnames, "${count.index}.zone")}"
  name = "${lookup(var.hostnames, count.index)}_volume_1"
  description = "${lookup(var.hostnames, count.index)}_volume_1 in ${lookup(var.hostnames, "${count.index}.region")}${lookup(var.hostnames, "${count.index}.zone")}"
  size = 200
}

resource "openstack_blockstorage_volume_v1" "block_storage_2" {
  count = "${var.count}"
  region = "${lookup(var.hostnames, "${count.index}.region")}"
  availability_zone = "${lookup(var.hostnames, "${count.index}.region")}${lookup(var.hostnames, "${count.index}.zone")}"
  name = "${lookup(var.hostnames, count.index)}_volume_2"
  description = "${lookup(var.hostnames, count.index)}_volume_1 in ${lookup(var.hostnames, "${count.index}.region")}${lookup(var.hostnames, "${count.index}.zone")}"
  size = 50
}


resource "openstack_lb_pool_v1" "lbaas_pool_1" {
  name = "poc_lbaas_pool_1"
  region = "${lookup(var.defaults, "region")}"
  protocol = "HTTP"
  subnet_id = "${lookup(var.defaults, "lbaas_subnet")}"
  lb_method = "ROUND_ROBIN"
  monitor_ids = ["${openstack_lb_monitor_v1.lbaas_monitor_1.id}"]
  member {
    address = "${element(openstack_compute_instance_v2.compute_worker.*.access_ip_v4, 0)}"
    port = 80
    region = "${lookup(var.defaults, "region")}"
    admin_state_up = "true"
  }
  member {
    address = "${element(openstack_compute_instance_v2.compute_worker.*.access_ip_v4, 1)}"
    port = 80
    region = "${lookup(var.defaults, "region")}"
    admin_state_up = "true"
  }
}

resource "openstack_lb_monitor_v1" "lbaas_monitor_1" {
  region = "${lookup(var.defaults, "region")}"	
  type = "HTTP"
  http_method = "GET"
  expected_codes = "200"
  url_path = "/"
  delay = 10
  timeout = 5
  max_retries = 3
  admin_state_up = "true"
}

resource "openstack_networking_floatingip_v2" "lbaas_floatip_1" {
  region = "${lookup(var.defaults, "region")}"
  pool = "LBaaS"
}

resource "openstack_lb_vip_v1" "lbaas_vip_1" {
  depends_on = "openstack_networking_floatingip_v2.lbaas_floatip_1"
  name = "poc_webapp_vip"
  region = "${lookup(var.defaults, "region")}"
  subnet_id = "${lookup(var.defaults, "lbaas_subnet")}"
  protocol = "HTTP"
  port = 80
  pool_id = "${openstack_lb_pool_v1.lbaas_pool_1.id}"
  #floating_ip  = "${openstack_networking_floatingip_v2.lbaas_floatip_1.address}"
  #address  = "${openstack_networking_floatingip_v2.lbaas_floatip_1.address}"
}

output "vip_address" {
  value = "${openstack_lb_vip_v1.lbaas_vip_1.address}"
}

resource "openstack_compute_instance_v2" "compute_worker" {
  count = "${var.count}"
  volume {
    volume_id = "${element(openstack_blockstorage_volume_v1.block_storage_1.*.id, count.index)}"
  }
  volume {
    volume_id = "${element(openstack_blockstorage_volume_v1.block_storage_2.*.id, count.index)}"
  }
  name = "${lookup(var.hostnames, count.index)}"
  region = "${lookup(var.hostnames, "${count.index}.region")}"
  availability_zone = "${lookup(var.hostnames, "${count.index}.region")}${lookup(var.hostnames, "${count.index}.zone")}"
  image_id = "${lookup(var.defaults, "image")}"
  flavor_id = "${lookup(var.defaults, "flavor")}"
  network = {
    uuid = "${lookup(var.defaults, "network")}"
    name = "public"
  }
  metadata {
    this = "that"
  }
  key_pair = "${lookup(var.defaults, "key_pair")}"
  security_groups = ["default"]
  
  admin_pass = "${lookup(var.defaults, "password")}"
  
  # This is where we would do CUDL registration, etc...
 # provisioner "local-exec" {
 #       command = "export PYTHONPATH=/usr/lib64/python2.6/site-packages/pycrypto-2.6.1-py2.6-linux-x86_64.egg; python -c \"server_ip='${self.access_ip_v4}'; ${element(template_file.cda_automation.*.rendered, count.index)}\""
 # }
  
  # Doing stuff...
  provisioner "remote-exec" {
    connection {
        user = "${lookup(var.defaults, "username")}"
        password = "${self.admin_pass}"
    }  
    inline = [
     #"sudo puppet agent -t",
     "sudo yum -y install httpd",
     "sudo /etc/init.d/httpd start",
	 "sudo bash -c \"echo \\\"${element(template_file.index_html.*.rendered, count.index)}\\\" > /var/www/html/index.html\""
     ]
  }

  # Creating run-deck nodes
  provisioner "remote-exec" {
    connection {
        user = "${lookup(var.rundeck, "username")}"
        password = "${lookup(var.rundeck, "password")}"
        host = "${lookup(var.rundeck, "host")}"
       
    }
    inline = [
         "sudo bash -c 'printf \"${lookup(var.defaults, "password")}\" > \"${lookup(var.rundeck, "keys")}/cloud.password\"  ; for host in ${lookup(var.hostnames, count.index)}; do echo \"$host:\"; echo \"  hostname: ${self.access_ip_v4}\"; echo \"  username: ${lookup(var.defaults, "username")}\"; echo \"  ssh-password-storage-path: keys/cloud.password \"; echo \"  tags:\"; echo \"    - ${lookup(var.rundeck, "tags")}\" ; echo \"  ssh-authentication: password\"; echo \"  sudo-command-enabled: true\"; done >> ${lookup(var.rundeck, "ressources")};'"
     ]
  }

  
   provisioner "file" {
     connection {
       user = "${lookup(var.defaults, "username")}"
       password = "${self.admin_pass}"
     }    
     source = "templates/index.tpl"
     destination = "/tmp/example.conf"
   }
    
}

resource "template_file" "index_html" {
    count = "${var.count}"
	filename = "./templates/index.tpl"
    vars {
        hostname = "${lookup(var.hostnames, count.index)}"
    }
}

resource "template_file" "cda_automation" {
    count = "${var.count}"
	filename = "./templates/cda_automation.tpl"
    vars {
        hostname = "${lookup(var.hostnames, count.index)}"
        #server_ip = "${element(openstack_compute_instance_v2.compute_worker.*.access_ip_v4, count.index)}"
        username = "${lookup(var.defaults, "username")}"
        password = "${lookup(var.defaults, "password")}"
        environment = "${lookup(var.cda, "environment")}"
        component = "${lookup(var.cda, "component")}"
        component_version = "${lookup(var.cda, "component_version")}"
        new_stack_version = "${lookup(var.cda, "new_stack_version")}"
        component_stack_name = "${lookup(var.cda, "component_stack_name")}"
        server_type = "${lookup(var.cda, "server_type")}"		
        deployment_group_name = "${lookup(var.cda, "deployment_group_name")}"		
    }
}

output debug_1 {
  value = "${template_file.index_html.0.rendered}"
}

output debug_2 {
  value = "${template_file.cda_automation.1.rendered}"
}

output display_floating_ip {
  value = "${openstack_networking_floatingip_v2.lbaas_floatip_1.address}"
}

output display_lb_pool {
  value = "${openstack_lb_pool_v1.lbaas_pool_1.member.*}"
}
