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
echo 'deb https://deb.nodesource.com/node_6.x wily main' > /etc/apt/sources.list.d/nodesource.list
echo 'deb-src https://deb.nodesource.com/node_6.x wily main' >> /etc/apt/sources.list.d/nodesource.list

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


echo "** Install virtualenv **"
pip install virtualenv


echo "** Install elasticdump **"
npm install elasticdump -g


# Install Oracle Java
echo "** Install OracleJDK **"
cd /tmp
wget -nv --header "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jdk/8u131-b11/d54c1d3a095b4ff2b6607d096fa80163/jdk-8u131-linux-x64.tar.gz

mkdir /opt/jdk || true
tar -zxf jdk-8u131-linux-x64.tar.gz -C /opt/jdk
rm jdk-8u131-linux-x64.tar.gz
update-alternatives --install /usr/bin/java java /opt/jdk/jdk1.8.0_131/bin/java 100
update-alternatives --install /usr/bin/javac javac /opt/jdk/jdk1.8.0_131/bin/javac 100
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

echo "** Install Kibana Plugins **"
/usr/share/kibana/bin/kibana-plugin -i elastic/timelion
/usr/share/kibana/bin/kibana-plugin -i tagcloud -u https://github.com/stormpython/tagcloud/archive/master.zip
chown -R kibana:kibana /usr/share/kibana

echo "** Start Kibana **"
systemctl enable kibana
systemctl start kibana


echo "** make screeps-stats project **"
cd $DIR/../
make


echo "** install screeps-stats project **"
make install

