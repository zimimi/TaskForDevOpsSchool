#!/bin/bash
sudo apt update
sudo apt install -y nginx

cat > /etc/logrotate.d/nginx_logs_rotate_every_15min << 'EOM'
/var/log/nginx/access.log {
	rotate 10
	dateext dateformat -%Y%m%d-%s
	compress
	create 664 nginx root
	prerotate
		#прибрати рядки, що містять "192.168.0.100" або "127.0.0.1"
		sed -i '/192.168.0.100\|127.0.0.1/d' $1
		#прибрати рядки, що містять "00:00", а наприкінці "/reinit"
		sed -i '/^00:00.*\/reinit$/d' $1
		# замінити підрядки формату "$md5hash_of_record-date$username", на "*****"
		# тут я не до кінця зрозумів завдання, тому зробив два приклади
		# приклад1: "$md5hash_of_01051999$abc@example.com", замінити на "*****"
		sed -i 's/$md5hash_of_[0-9]\{8\}\$[a-zA-Z]\{2,3\}@[^@]*\.[^@ ]*/*****/g' $1
		# приклад2: "$e64e7ecce3d76a8a3534b05c9baa6be1$abc@example.com", замінити на "*****"
		sed -i 's/$[0-9a-f]\{32\}\$[a-zA-Z]\{2,3\}@[^@]*\.[^@ ]*/*****/g' $1
	endscript
	postrotate
		# перезавантажити файли конфігурації, щоб nginx записував логи в новостворений файл access.log
		invoke-rc.d nginx reload
	endscript
	preremove
		# перед видаленням відправляти зайвий файл на backuper@192.168.0.43:/var/log/storage
		sudo scp -i "/root/.ssh/backuper" $1 backuper@192.168.0.43:/var/log/storage
	endscript
}
EOM

cat > /etc/logrotate.d/nginx_logs_rotate_every_day << 'EOM'
/var/log/nginx/chunga.log
/var/log/nginx/error.log
/var/log/nginx/seo.log
/var/log/nginx/custom.log {
	rotate 10
	compress
	dateext
	create 664 nginx root
	prerotate
		#прибрати рядки, що містять "192.168.0.100" або "127.0.0.1"
		sed -i '/192.168.0.100\|127.0.0.1/d' $1
		#прибрати рядки, що містять "00:00", а наприкінці "/reinit"
		sed -i '/^00:00.*\/reinit$/d' $1
		# замінити підрядки формату "$md5hash_of_record-date$username", на "*****"
		# тут я не до кінця зрозумів завдання, тому зробив два приклади
		# приклад1: "$md5hash_of_01051999$abc@example.com", замінити на "*****"
		sed -i 's/$md5hash_of_[0-9]\{8\}\$[a-zA-Z]\{2,3\}@[^@]*\.[^@ ]*/*****/g' $1
		sed -i 's/$md5hash_of_[0-9][0-9][0-1][0-9][1-2][0,9][0-9][0-9]\$[a-zA-Z]\{2,3\}@[^@]*\.[^@ ]*/*****/g' $1
		# приклад2: "$e64e7ecce3d76a8a3534b05c9baa6be1$abc@example.com", замінити на "*****"
		sed -i 's/$[0-9a-f]\{32\}\$[a-zA-Z]\{2,3\}@[^@]*\.[^@ ]*/*****/g' $1
	endscript
	postrotate
		# перезавантажити файли конфігурації, щоб nginx записував логи в новостворені файли chunga.log, error.log, seo.log, custom.log
		invoke-rc.d nginx reload
	endscript
	preremove
		# перед видаленням відправляти зайвий файл на backuper@192.168.0.43:/var/log/storage
		sudo scp -i "/root/.ssh/backuper" $1 backuper@192.168.0.43:/var/log/storage
	endscript
}
EOM
# записати рядок */15 * * * * root logrotate -f /etc/logrotate.d/nginx_logs_rotate_every_15min у файл /etc/crontab
sudo sh -c 'echo \*/15 \* \* \* \* root logrotate -f /etc/logrotate.d/nginx_logs_rotate_every_15min >> /etc/crontab'
# записати рядок * 4 * * * root logrotate -f /etc/logrotate.d/nginx_logs_rotate_every_day у файл /etc/crontab
sudo sh -c 'echo \* 4 \* \* \* root logrotate -f /etc/logrotate.d/nginx_logs_rotate_every_day >> /etc/crontab'
