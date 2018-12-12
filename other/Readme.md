# vhost
### The script wasn't written by me, I just simplified it a bit for own purposes!

## Installation
1. `sudo mv ~/Downloads/vhost /usr/local/sbin/`
2. `chmod +x /usr/local/sbin/vhost`

## Usage

### Add new host
```bash
sudo vhost add -n my-awesome-site.local -a www.my-awesome-site.local -d /var/www/my_site_folder/
```

### Remove host
```bash
sudo vhost remove -n my-awesome-site.local
```
