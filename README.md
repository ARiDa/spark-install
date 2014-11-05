spark-install
=============

Script to support Spark standalone mode install

How to use
==========
Firstly, include the slaves on **slaves** file.

## Install on the master
``` bash
$ wget https://github.com/ARiDa/spark-install/archive/master.zip
$ unzip master
$ cd spark-install-master/
$ ./install-spark-single-node.sh "m"
$ ./install-public-key-slaves.sh
```
where "m" stands for master, and install-public-key-slaves.sh is gonna install the public key on the slaves

## Install on the slaves
On each slave, do the following
``` bash
$ wget https://github.com/ARiDa/spark-install/archive/master.zip
$ unzip master
$ cd spark-install-master/
$ ./install-spark-single-node.sh
```
