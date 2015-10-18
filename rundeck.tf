
provider "rundeck" {
    url = "https://rundeck-01-alpha.amers2.cis.trcloud:4443"
    auth_token = "wL8MgnfNz0FTH1XT1LX9TOuoysnPZJjo"
    allow_unverified_ssl = true
}

resource "rundeck_project" "poc" {
    name = "poc"
    description = "Proof of concept project via Terraform"

    resource_model_source {
        type = "file"
        config = {
            format = "resourceyaml"
            # This path is interpreted on the Rundeck server.
            file = "${lookup(var.rundeck, "ressources")}"
        }
    }
}

resource "rundeck_job" "poc.job" {
    name = "poc.job"
    project_name = "poc"
    node_filter_query = "tags: poc"
    description = "Restart the service daemons on all the web servers"
    allow_concurrent_executions = 1

    command {
        shell_command = "sudo service httpd restart"
    }
}
