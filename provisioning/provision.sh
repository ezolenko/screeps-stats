#!/usr/bin/env bash

set -e
set -u

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd -P )"
cd $DIR
pwd

apt_quiet_install () {
   echo "** Install package $1 **"
   DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" -y -f -q install $1
}


# Upgrade Package Manager
echo "** Add Package Manager Repositories **"

# elasticsearch and kibana repositories repository
wget -qO - https://packages.elastic.co/GPG-KEY-elasticsearch | apt-key add -
echo "deb https://artifacts.elastic.co/packages/5.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-5.x.list



# Node repository
wget -qO- https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add -
echo 'deb https://deb.nodesource.com/node_6.x xenial main' > /etc/apt/sources.list.d/nodesource.list
echo 'deb-src https://deb.nodesource.com/node_6.x xenial main' >> /etc/apt/sources.list.d/nodesource.list

apt-get update


# Install Development Tools
echo "** Install Development Tools **"
apt_quiet_install git
apt_quiet_install nodejs
apt_quiet_install python-dev
apt_quiet_install libffi-dev
apt_quiet_install libssl-dev
apt_quiet_install libxml2-dev
apt_quiet_install libxslt-dev
apt_quiet_install libyaml-dev
apt_quiet_install python-pip
apt_quiet_install apache2-utils
apt_quiet_install nginx


echo "** Install virtualenv **"
pip install virtualenv


echo "** Install elasticdump **"
npm install elasticdump -g


# Install OpenJDK Java
echo "** Install OpenJDK **"
apt-get install --yes openjdk-8-jre-headless
cd $DIR


# Install ElasticSearch
echo "** Install ElasticSearch **"
apt_quiet_install elasticsearch
cp $DIR/etc/elasticsearch/* /etc/elasticsearch
update-rc.d elasticsearch defaults 95 10
systemctl enable elasticsearch
systemctl start elasticsearch


# Install Kibana
echo "** Install Kibana **"
apt_quiet_install kibana
mkdir /etc/kibana || true
cp $DIR/etc/kibana/kibana.yml /etc/kibana/kibana.yml
update-rc.d kibana defaults 96 9

echo "** Load Kibana Indexes **"
$DIR/bin/import_kibana_indexes.sh

echo "** Start Kibana **"
systemctl enable kibana
systemctl start kibana


cp $DIR/etc/nginx/sites-available/default /etc/nginx/sites-available/default
systemctl enable nginx


echo "** make screeps-stats project **"
cd $DIR/../
make


echo "** install screeps-stats project **"
make install

