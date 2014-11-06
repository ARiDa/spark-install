spark-install
=============

Script to support Spark standalone mode install

How to use
==========
Firstly, include the slaves on **slaves** file. For example
```
localhost
10.102.12.59
10.102.12.123
```

## Install on the master
``` bash
$ cd ; rm -r master.zip spark-install* ; wget https://github.com/ARiDa/spark-install/archive/master.zip ; unzip master ; cd spark-install-master/ ; ./install-spark-single-node.sh master
```

## Install on the slaves
On each slave, do the following
``` bash
$ cd ; rm -r master.zip spark-install* ; wget https://github.com/ARiDa/spark-install/archive/master.zip ; unzip master ; cd spark-install-master/ ; ./install-spark-single-node.sh slave
```
