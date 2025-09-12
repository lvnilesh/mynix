sudo install -d -m700 /etc/samba
sudo tee /etc/samba/creds-cloudgenius <<'EOF'
username=cloudgenius
password=password
EOF
sudo chmod 600 /etc/samba/creds-cloudgenius
