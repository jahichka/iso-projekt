#!/bin/bash
yum update -y
yum install -y docker git

systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user

curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

sleep 30

mkfs -t ext4 /dev/xvdf
mkdir -p /mnt/ebs-data
mount /dev/xvdf /mnt/ebs-data
echo '/dev/xvdf /mnt/ebs-data ext4 defaults,nofail 0 2' >> /etc/fstab

cd /home/ec2-user
git clone ${git_repo_url} app
cd app

chown -R ec2-user:ec2-user /home/ec2-user/app
chown -R ec2-user:ec2-user /mnt/ebs-data

sudo -u ec2-user docker-compose -f docker-compose.frontend.yml up -d

cat > /etc/logrotate.d/docker-app << EOF
/var/lib/docker/containers/*/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 0644 root root
}
EOF