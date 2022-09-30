#!/bin/bash
mkdir -p /home/student/.ssh
mv /home/student/authorized_keys /home/student/.ssh
chown -R student:student /home/student/.ssh
echo "PubkeyAuthentication yes" >> /etc/ssh/sshd_config
echo "PasswordAuthentication no" >> /etc/ssh/sshd_config
service ssh restart