#!/bin/bash
yum update -y
yum install -y docker git

systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user

curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

sleep 30

if [ -e /dev/xvdf ]; then
    if ! blkid /dev/xvdf; then
        mkfs -t ext4 /dev/xvdf
    fi
    
    mkdir -p /mnt/ebs-data
    mount /dev/xvdf /mnt/ebs-data
    echo '/dev/xvdf /mnt/ebs-data ext4 defaults,nofail 0 2' >> /etc/fstab
    
    mkdir -p /mnt/ebs-data/frontend
    mkdir -p /mnt/ebs-data/logs
fi

cd /home/ec2-user
git clone ${git_repo_url} app || {
    echo "Git clone failed, trying alternative..."
    mkdir -p app
    cd app
    git init
}

cd /home/ec2-user/app

chown -R ec2-user:ec2-user /home/ec2-user/app
chown -R ec2-user:ec2-user /mnt/ebs-data

sudo -u ec2-user docker-compose up -d frontend

sleep 30

if ! docker ps | grep noteapp-frontend; then
    echo "Frontend container failed to start, trying direct docker run..."
    cd frontend
    sudo -u ec2-user docker build -t frontend-app .
    sudo -u ec2-user docker run -d -p 8080:8080 --name noteapp-frontend --restart unless-stopped frontend-app
fi

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