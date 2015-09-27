from conductor.cda import CDAutomater
# SSH username and password to use for login to server
# Password may be omitted if SSH public key authentication
# is used instead
username, password = '${username}', '${password}'
_cda = CDAutomater(username=username, password=password)
environment = '${environment}'
component = '${component}'
component_version = '${component_version}'
new_stack_version = '${new_stack_version}'
component_stack_name = '${component_stack_name}'
deployment_group_name = '${deployment_group_name}'
server_type = '${server_type}'
# Hostname of server to deploy on. May be either short hostname
# or FQDN. If DNS lookup is not possible, a server ip can be provided
# instead via ``server_ip=<ip>``
server_name = '${hostname}'
_cda.register_cda_run_puppet(component, component_version, new_stack_version,
                             server_name, environment, server_type,
                             component_stack_name=component_stack_name, deployment_group_name=deployment_group_name, server_ip=server_ip)
