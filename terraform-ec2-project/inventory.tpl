[webservers]
${instance_ip} ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/test-key ansible_ssh_common_args='-o StrictHostKeyChecking=no'
