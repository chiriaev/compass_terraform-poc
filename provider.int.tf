provider "openstack" {
    user_name  = "${lookup(var.openstack, "user_name")}"
    tenant_name = "${lookup(var.openstack, "tenant_name")}"
    password  = "${lookup(var.openstack, "password")}"
    auth_url  = "${lookup(var.openstack, "auth_url")}"
}
