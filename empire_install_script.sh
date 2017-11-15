#!/bin/bash

if [[ $EUID -ne 0 ]]; then
	echo " [!]This script must be run as root" 1>&2
	exit 1
fi

if [[ $( uname -m ) -ne x86_64 ]]; then
	echo " [!]This script only supports x86_64 systems" 1>&2
	exit 1
fi

function pip_packages {
	pip install --upgrade urllib3
	pip install setuptools
	pip install pycrypto
	pip install iptools
	pip install pydispatcher
	pip install flask
	pip install macholib
	pip install dropbox
	pip install 'pyopenssl==17.2.0'
	pip install pyinstaller
	pip install zlib_wrapper
	pip install netifaces
}

function git_repos {
	git clone --depth=1 https://github.com/EmpireProject/Empire.git
	git clone --depth=1 https://github.com/hogliux/bomutils.git
}

function powershell_install {
	if ! which powershell > /dev/null; then
		if lsb_release -d | grep -q "Fedora"; then
			rpm --import https://packages.microsoft.com/keys/microsoft.asc
			curl https://packages.microsoft.com/config/rhel/7/prod.repo | tee /etc/yum.repos.d/microsoft.repo
			dnf update
			dnf install -y compat-openssl10 powershell
			
		elif lsb_release -d | grep -q "Kali"; then
			apt-get update
			apt-get install curl gnupg apt-transport-https
			curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add -
			sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/microsoft-debian-stretch-prod stretch main" > /etc/apt/sources.list.d/microsoft.list'
			apt-get update
			apt-get install -y powershell
	
		elif lsb_release -d | grep -q "Ubuntu"; then
			curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add -
			curl https://packages.microsoft.com/config/ubuntu/17.04/prod.list | tee /etc/apt/sources.list.d/microsoft.list
			apt-get update
			apt-get install -y powershell
		
		elif lsb_release -d | grep -q "Debian"; then
			curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add -
			sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/microsoft-debian-stretch-prod stretch main" > /etc/apt/sources.list.d/microsoft.list'
			apt-get update
			apt-get install -y powershell
			
		else
			echo "Unknown distro - powershell install cannot proceed..."
			exit 1;
		fi
	fi
}

function osx_utils_install {
	tar -xvf ../data/misc/xar-1.5.2.tar.gz
	cd xar-1.5.2 && ./configure
	make
	make install
	
	cd ../../../bomutils && make
	make install
	chmod 755 build/bin/mkbom
	cp bomutils/build/bin/mkbom /usr/local/bin/mkbom
	
	cd ../empire/setup/
}

function cert_create {
	openssl req -new -x509 -keyout ../data/empire-priv.key -out ../data/empire-chain.pem -days 365 -nodes -subj "/C=US" >/dev/null 2>&1

	echo -e "\n [*] Certificate written to ../data/empire-chain.pem"
	echo -e "\r [*] Private key written to ../data/empire-priv.key\n"
}

git_repos
cd Empire/setup

if lsb_release -d | grep -q "Fedora"; then
	Release=Fedora
	dnf install -y make g++ python-devel m2crypto python-m2ext swig python-iptools python3-iptools libxml2-devel default-jdk openssl-devel libssl1.0.0 libssl-dev
	pip_packages
	powershell_install
	osx_utils_install

elif lsb_release -d | grep -q "Kali"; then
	Release=Kali
	apt-get update
	apt-get install -y make g++ zlib1g-dev python-dev python-m2crypto swig python-pip libxml2-dev default-jdk libffi-dev libssl-dev libssl1.0-dev
	pip_packages
	powershell_install
	osx_utils_install

elif lsb_release -d | grep -q "Ubuntu"; then
	Release=Ubuntu
	apt-get install -y make g++ zlib1g-dev python-dev python-m2crypto swig python-pip libxml2-dev default-jdk libssl-dev libffi-dev libssl1.0-dev
	pip_packages
	powershell_install
	osx_utils_install

elif [ -f /usr/bin/apt-get ]; then
	echo "Looks like a Debian/Ubuntu variant. Trying apt-get..."
 	apt-get install -y make g++ zlib1g-dev python-dev python-m2crypto swig python-pip libxml2-dev default-jdk libffi-dev libssl-dev libssl1.0-dev
 	pip_packages
 	powershell_install
 	osx_utils_install

else
	echo "Unknown distro - install cannot proceed..."
	exit 1;
fi

# set up the database schema
./setup_database.py

cert_create

cd ../..

echo -e '\n [*] Setup complete!\n'
