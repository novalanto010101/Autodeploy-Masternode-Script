#!/bin/bash

echo -e "create swap ...\n\n"
sudo touch /var/swap.img
sudo chmod 600 /var/swap.img
sudo dd if=/dev/zero of=/var/swap.img bs=1024k count=2000
mkswap /var/swap.img
sudo swapon /var/swap.img
sudo echo "/var/swap.img none swap sw 0 0" >> /etc/fstab

echo -e "\n\nupdate & prepare system ...\n\n"
sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get dist-upgrade -y
sudo apt-get install nano htop git -y

sudo apt-get install build-essential libtool autotools-dev automake pkg-config libssl-dev libevent-dev bsdmainutils software-properties-common python-software-properties libzmq5-dev libminiupnpc-dev unzip -y
sudo apt-get install libboost-all-dev -y
sudo add-apt-repository ppa:bitcoin/bitcoin -y
sudo apt-get update -y
sudo apt-get install libdb4.8-dev libdb4.8++-dev -y
apt install unzip

echo -e "\n\nsetup volkshashd ...\n\n"
cd ~
wget https://github.com/VolkshashDEV/volkshashcore/releases/download/0.13.2.1/Volkshash.Linux.GNU.x64.0.13.2.1.zip
chmod -R 755 /root/Volkshash.Linux.GNU.x64.0.13.2.1.zip
unzip Volkshash.Linux.GNU.x64.0.13.2.1.zip
sleep 5
mkdir /root/volkshash
mkdir /root/.volkshash
cp /root/Volkshash.Linux.GNU.x64.0.13.2.1//volkshashd /root/volkshash
cp /root/Volkshash.Linux.GNU.x64.0.13.2.1//volkshash-cli /root/volkshash
sleep 5
chmod -R 755 /root/volkshash
chmod -R 755 /root/.volkshash

echo -e "\n\nlaunch volkshashd ...\n\n"
sudo apt-get install -y pwgen
GEN_PASS=`pwgen -1 20 -n`
IP_ADD=`curl ipinfo.io/ip`

echo -e "rpcuser=volkshashuser\nrpcpassword=${GEN_PASS}\nserver=1\nlisten=1\nmaxconnections=256\ndaemon=1\nrpcallowip=127.0.0.1\nexternalip=${IP_ADD}:17375\nstaking=0" > /root/.volkshash/volkshash.conf
cd /root/volkshash
./volkshashd
sleep 40
masternodekey=$(./volkshash-cli masternode genkey)
./volkshash-cli stop

# add launch after reboot
crontab -l > tempcron
echo "@reboot /root/volkshash/volkshashd -reindex >/dev/null 2>&1" >> tempcron
crontab tempcron
rm tempcron

echo -e "masternode=1\nmasternodeprivkey=$masternodekey\n\n\n" >> /root/.volkshash/volkshash.conf
echo -e "addnode=102.219.85.87:17375" >> /root/.volkshash/volkshash.conf
echo -e "addnode=102.219.85.13:17375" >> /root/.volkshash/volkshash.conf
echo -e "addnode=147.135.211.28:17375" >> /root/.volkshash/volkshash.conf


./volkshashd -daemon
cd /root/.volkshash
ufw allow 17375

echo -e "\n\nadding volkshashd system service ...\n\n"
touch /etc/systemd/system/volkshashd.service

cat <<EOF >> /etc/systemd/system/volkshashd.service
[Unit]
Description=volkshash
After=network.target
[Service]
Type=forking
User=root
WorkingDirectory=/root
ExecStart=/root/volkshash/volkshashd -conf=/root/.volkshash/volkshash.conf -datadir=/root/.volkshash
ExecStop=/root/volkshash/volkshash-cli -conf=/root/.volkshash/volkshash.conf -datadir=/root/.volkshash stop
Restart=on-failure
RestartSec=1m
StartLimitIntervalSec=5m
StartLimitInterval=5m
StartLimitBurst=3
[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable volkshashd
sudo systemctl start volkshashd

# output masternode key
echo -e "Masternode private key: $masternodekey"
echo -e "Welcome to the volkshash Masternode Network!"

