#!/bin/bash

sudo yum install -y $(cat pkglist.txt)

set -x

sudo chmod +rwx /home/cc

sudo getent group munge || sudo groupadd -g 1011 munge
sudo id -u munge || sudo useradd  -m -c "MUNGE Uid 'N' Gid Emporium" -d /var/lib/munge -u 1001 -g munge  -s /sbin/nologin munge
sudo getent group slurm || sudo groupadd -g 1012 slurm
sudo id -u slurm || sudo useradd  -m -c "SLURM workload manager" -d /var/lib/slurm -u 1002 -g slurm  -s /bin/bash slurm

sudo umount /home/cc/intel /home/cc/apps /home/cc/my_mounting_point /home/cc/container

mkdir -p /home/cc/container
cc-cloudfuse mount /home/cc/container

if [[ $1 = '--client' ]]; then

	mkdir -p /home/cc/intel
	mkdir -p /home/cc/apps
	sudo mount -t nfs $(cat headip):/home/cc/intel /home/cc/intel
	sudo mount -t nfs $(cat headip):/home/cc/apps /home/cc/apps

	setupdir=/home/cc/apps/setup
	sudo bash $setupdir/setup-compute-node
 
elif [[ $1 = '--host' ]]; then

	mkdir -p /home/cc/intel
	mkdir -p /home/cc/apps
        tar -x -I=pigz -f ~/apps.pigz
	tar -x -I=pigz -f ~/intel.pigz

 	for dir in apps intel
  	do
		echo "/home/cc/$dir *(rw,sync,no_subtree_check,no_root_squash)" | sudo tee -a /etc/exports
 	done
  
  	exportfs -a
  	sudo systemctl restart nfs-server

        read -p "input HEAD ip: " $headip
	echo $headip > headip
 
	echo "" > ~/apps/hostfile
	while [[ 1 ]]; do
		read -p "input WORKER ip in order (empty to terminate): " $workerip
  		if [[ -z $workerip ]]; then
  			break
    		fi
      		echo $workerip >> ~/apps/hostfile
 	done
	./write-hosts.sh $headip
 
 	setupdir=/home/cc/apps/setup
	sudo bash $setupdir/setup-head-node

fi

echo "IP FILES HAVE BEEN UPDATED, PLEASE GIT ADD + COMMIT!"
cat hosts | sudo tee /etc/hosts
