# wordpress-ansible

ansible playbook that install and copy all nessesary files to bring up Wordpress blog in Docker on Ubuntu 16.04 host.

Pre-requests
------------
install ansible 
```brew install ansible```

Use
----

- put server IP and credentials to hosts.list file
Example:
```
[default]
ip_address

[default:vars]
ansible_user=root
ansible_ssh_private_key_file=path_to_privat_key
```

- run command:
```ansible-playbook -i host.list --extra-vars="sitename=blog.site.com mysqlpass=aqwe123" playbook.yml```

where blog.site.com - site name; aqwe123 - mysql password

- connect to server and run commands to start:
```cd /root/blog/
docker-compose up -d```


To use ssl on site
------------------
- put fullchain.pem & privkey.pem to wordpress-data/nginx/ssl 
- rename ansible/template/blog_ssl.js to blog.js with replacement

To use with backupt data
------------------------
- copy db data to the wordpress-data/db-data
- copy wordpress data to the wordpress-data/wordpress