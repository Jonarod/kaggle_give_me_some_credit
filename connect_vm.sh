# Start a VM (Go to AWS and start an EC2 instance)

# Collect basic infos
VM_USER = "centos"                      # Collect VM's public IP
VM_IP = "52.51.181.250"                 # Collect VM's public IP
SSH_KEY_PATH = "~/.ssh/AWS-CABD.pem"    # Collect VM's private ssh-key

# Upload file to the VM (AWS EC2)
file_copy = `sudo scp -i $SSH_KEY_PATH ~/Downloads/dataset/regions.csv $VM_USER@$VM_IP:/home/centos`

# Open a connection into the distant VM through ssh
ssh_connection = `ssh -i $SSH_KEY_PATH $VM_USER@$VM_IP`
$ssh_connection  # execute the command

# Go in root mode
sudo su

# Start the docker daemon 
service docker start

# Check running images
# docker ps   

# Check already installed images
# docker images

# Stop the docker daemon 
# service docker stop


# Run an image with a volume
######################
# FROM HERE: using the docs in https://github.com/Yannael/kafka-sparkstreaming-cassandra
######################
HOST_DIR = `pwd`
CONTAINER_DIR = "/home/guest/dataset"
cd dataset
docker run -v $HOST_DIR:$CONTAINER_DIR -p 4040:4040 -p 8888:8888 -p 23:22 -ti --privileged yannael/kafka-sparkstreaming-cassandra

# Copy files from the VM to the container
# Since we mounted a volume to connect host files into the container, this step might not be necessary, but just in case:
# CONTAINER_ID = "2d78bd67e5f2"
# sudo docker cp       file in the VM   container's ID : folder in container      
#                 vvvvvvvvvvvvvvvvvvvvvvv vvvvvvvvvvvvv:vvvvvvvv
# sudo docker cp /home/centos/regions.csv $CONTAINER_ID:/dataset

# Start services
sh /usr/bin/startup_script.sh


# Connect to spark via pyspark
sh spark/bin/pyspark

# Open jupyter notebook at given port
# Check where your runtime folder is located:
#jupyter --paths
# Remove all files in the runtime folder:
#rm -r [path to runtime folder]/*
# Check with top if there are any jupyter notebook running processes left, and if so kill their PID.
#top | grep jupyter &
#kill [PID]
# Then relaunch your notebook on the desired ip and port:
jupyter notebook --ip=127.0.0.1 --port=8888 --allow-root


# Load a local file into spark
#import des librairies
import os
os.environ['PYSPARK_SUBMIT_ARGS'] = '--conf spark.ui.port=4040 --packages com.datastax.spark:spark-cassandra-connector_2.11:2.3.2 pyspark-shell'
import time

#initiation de context de spark cassandra
from pyspark import SparkContext, SparkConf
from pyspark.sql import SQLContext, Row
conf = SparkConf() \
    .setAppName("csv to cassandra") \
    .setMaster("local[2]") \
    .set("spark.cassandra.connection.host", "127.0.0.1")
sc = SparkContext.getOrCreate(conf=conf) 
sqlContext=SQLContext(sc)

# AS RDD
# regionsRDD = sc.textFile("file:///home/guest/dataset/regions.csv").map( lambda x: x.split(",") );
# regionsRDD.collect();

# AS DF
regionsDF = sqlContext.read.format('com.databricks.spark.csv').options(header='true', inferschema='true', sep=",").load("file:///home/guest/dataset/regions.csv",header=True);
regionsDF.show()

# Store the DF as a permanent table into spark (dbfs)
regionsDF.write.format("parquet").saveAsTable("regions");

# Test SQL query works
sqlDF = spark.sql("SELECT * FROM regions");
sqlDF.show();


citiesDF = sqlContext.read.format('com.databricks.spark.csv').options(header='true', inferschema='true', sep=",").load("file:///home/guest/dataset/cities.csv",header=True);
citiesDF.show();
citiesDF.write.format("parquet").saveAsTable("cities");

monumentsDF = sqlContext.read.format('com.databricks.spark.csv').options(header='true', inferschema='false', sep="|").load("file:///home/guest/dataset/palissy-MH-valid.csv.utf",header=True);
monumentsDF.show();
monumentsDF.write.format("parquet").saveAsTable("monuments");

departmentsDF = sqlContext.read.format('com.databricks.spark.csv').options(header='true', inferschema='true', sep=",").load("file:///home/guest/dataset/departments.csv",header=True);
departmentsDF.show();
departmentsDF.write.format("parquet").saveAsTable("departments");


# Func to save data into cassandra
def saveToCassandra(rows, myKeyspace, myTable):
    if not rows.isEmpty(): 
        sqlContext.createDataFrame(rows).write\
        .format("org.apache.spark.sql.cassandra")\
        .mode('append')\
        .options(table=myTable, keyspace=myKeyspace)\
        .save()

# saveToCassandra(regionsDF.rdd, "datatable", "regions")
# saveToCassandra(citiesDF.rdd, "datatable", "cities")
# saveToCassandra(departmentsDF.rdd, "datatable", "departments")
# saveToCassandra(monumentsDF.rdd, "datatable", "monuments")

# Query directly from cassandra
data=sqlContext.read\
    .format("org.apache.spark.sql.cassandra")\
    .options(table="monuments", keyspace="datatable")\
    .load()
data.show()



####################################################
# OPEN A NEW TERMINAL
####################################################
# Open cassandra via another terminal, logging into the same containerID
# sudo docker exec -it 42cee803da24 bash
sudo docker exec -it 42cee803da24 cqlsh

# Create a new keyspace
CREATE KEYSPACE IF NOT EXISTS datatable WITH REPLICATION={'class': 'SimpleStrategy', 'replication_factor':1};
USE datatable;

# Add tables to that keyspace
CREATE TABLE regions (id VARCHAR, code  VARCHAR, name VARCHAR, slug VARCHAR, PRIMARY KEY( id ));
CREATE INDEX fk_regions_idx ON regions (code);
CREATE TABLE cities (id VARCHAR, department_code VARCHAR, insee_code VARCHAR, zip_code VARCHAR, name VARCHAR, slug VARCHAR, gps_lat VARCHAR, gps_lng VARCHAR, PRIMARY KEY(id));
CREATE INDEX fk_cities_idx ON cities (insee_code);
CREATE TABLE departments (id VARCHAR, region_code VARCHAR, code VARCHAR, name VARCHAR, slug VARCHAR, PRIMARY KEY(id));
CREATE INDEX fk_departments_idx1 ON departments (code);
CREATE INDEX fk_departments_idx2 ON departments (region_code);

CREATE TABLE monuments (ref VARCHAR, reg VARCHAR, dpt VARCHAR, com VARCHAR, insee VARCHAR, edif VARCHAR, deno VARCHAR, tico VARCHAR, matr VARCHAR, autr VARCHAR, scle VARCHAR, dpro VARCHAR, stat VARCHAR, PRIMARY KEY(ref));
CREATE INDEX fk_monuments_idx1 ON monuments (DPT);
CREATE INDEX fk_monuments_idx2 ON monuments (INSEE);


