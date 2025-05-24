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
    
    mkdir -p /mnt/ebs-data/mongodb
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

sudo -u ec2-user docker-compose up -d mongodb backend

sleep 60

if ! docker ps | grep noteapp-backend; then
    echo "Backend container failed to start, trying direct approach..."
    sudo -u ec2-user docker run -d \
        --name noteapp-mongodb \
        -p 27017:27017 \
        -v /mnt/ebs-data/mongodb:/data/db \
        --restart unless-stopped \
        mongo:5
    
    sleep 30
    
    cd backend
    sudo -u ec2-user docker build -t backend-app .
    sudo -u ec2-user docker run -d \
        --name noteapp-backend \
        -p 3000:3000 \
        --link noteapp-mongodb:mongodb \
        -e MONGO_URI=mongodb://mongodb:27017/noteapp \
        -e NODE_ENV=production \
        --restart unless-stopped \
        backend-app
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