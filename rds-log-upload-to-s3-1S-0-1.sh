#!/bin/bash

######################################################
# version 1S.0.1 2018-11-20
# Single File Version
# Derived from https://github.com/aws/aws-cli/issues/2268
# usage bash ./rds-log-upload-to-s3.sh RDSInstanceName postgresql.log.2017-02-09-15
#
# The script is provided as an example and may require modification
# This Bash script is intended to be run on AWS Amazon Linux on an EC2 instance with the current AWS CLI installed
# and AWS credentials properly (EC2 instance role) configured.
# AWS CLI - http://docs.aws.amazon.com/cli/latest/userguide/installing.html
# Configuring the CLI http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html
######################################################

#REMOVE FROM PUBLISHED FILE - REMOVE FROM PUBLISHED FILE
#++++++++++++Outline++++++++++++++++++
#*script usage
#*verify inputs
#*verify RDS instance
#-local sub directory
#*verify bucket
#-create bucket if not exist
#-get list of logs on RDS instance
#*DL log file ****prototyped
#*Upload to S3
#*verify file
#-write activity log
#-cleanup
#------------Outline------------------ 
#REMOVE FROM PUBLISHED FILE - REMOVE FROM PUBLISHED FILE

#REMOVE FROM PUBLISHED FILE - REMOVE FROM PUBLISHED FILE
# ###########DBcredentials
# user=$1
# password=$2
# databasename=$3
# hostname=$4
# BUCKETNAME=$5
#REMOVE FROM PUBLISHED FILE - REMOVE FROM PUBLISHED FILE

#++++++++++++script usage++++++++++++
#Script usage - invoked with -h or --help or no parameters
for arg in $@
do
	if [ "$arg" == "-h" ] || [ "$arg" == "--help" ] || [ "$arg" == "" ];
	then
		echo "usage: scriptname.sh RDSInstanceName LogFileName BucketName";
		exit 1;
	else
		:
	fi
done
#------------script usage------------

#++++++++++++Input Paramters++++++++++++
RDSINSTANCENAME=$1
FILE=$2
BUCKETNAME=$3
#------------Input Paramters------------

#++++++++++++Test Input Paramters++++++++++++
if [ "$1" == "" ] || [ "$2" == "" ] || [ "$3" == "" ];
then
	echo "usage: scriptname.sh RDSInstanceName LogFileName BucketName";
	exit 1;
else
	:
fi
#------------Test Input Paramters------------

#++++++++++++Test for bucket++++++++++++             
BUCKET_EXISTS=true
S3_CHECK=$(aws s3 ls "s3://${BUCKETNAME}" 2>&1)                                                                                                 
#Some sort of error happened with s3 check          
if [ $? != 0 ]                                 
then                                           
  NO_BUCKET_CHECK=$(echo $S3_CHECK | grep -c 'NoSuchBucket')
  if [ $NO_BUCKET_CHECK = 1 ]; then
    echo "Bucket does not exist"
	BUCKET_EXISTS=false
	#code here for append to script log - optional
	exit 1;
  else
	echo "Error checking S3 Bucket"                     
    echo "$S3_CHECK"
	#code here for append to script log - optional
    exit 1;                 
  fi 
else                                                                                                                                                                                         
  echo "Bucket exists"
fi
#------------Test for bucket------------

#++++++++++++Test for RDS Instance++++++++++++
EXISTINGINSTANCE=$(aws rds describe-db-instances \
    --query 'DBInstances[*].[DBInstanceIdentifier]' \
    --filters Name=db-instance-id,Values=$RDSINSTANCENAME \
    --output text \
    )

if [ -z $EXISTINGINSTANCE ]
then
    echo "RDS instance $RDSINSTANCENAME does not exist! ..exiting"
	#code here for append to script log - optional
	exit 1;
else
    echo "instance $RDSINSTANCENAME exists"
	#code here for append to script log - optional
fi
#------------Test for RDS Instance------------

#++++++++++++Test for log file on RDS Instance++++++++++++
LOGFILEEXISTS=$(aws rds describe-db-log-files --db-instance-identifier $RDSINSTANCENAME \
	--query 'DescribeDBLogFiles[*].[LogFileName]' \
	--filename-contains $FILE --output text)

if [ -z $LOGFILEEXISTS ]
then
    echo "RDS instance log file $FILE not found! ..exiting"
	#code here for append to script log - optional
	exit 1;
else
    echo "log file $FILE exists"
	#code here for append to script log - optional
fi
#------------Test for log file on RDS Instance------------

# ###########Other options
# backup_path="${HOME}/mysql_backup"
# date=$(date +"%d-%b-%Y")

# ###########create dir and permissions
# mkdir $backup_path
# umask 177 

#++++++++++++log download+++++++++++++
COUNTER=1
LASTFOUNDTOKEN=0
PREVIOUSTOKEN=0

rm -f ${FILE}

while [  $COUNTER -lt 10000 ]; do
	echo "Lets try and get ${FILE}.${COUNTER}"
	echo "The starting-token will be set to ${LASTFOUNDTOKEN}"
	PREVIOUSTOKEN=${LASTFOUNDTOKEN}
	
	#NOTE!!!!! --log-file-name error/${FILE} is specific to RDS postgres "error" directory and must be mondified to work with other RDS engine types
	aws rds download-db-log-file-portion --db-instance-identifier ${RDSINSTANCENAME} --log-file-name error/${FILE} --starting-token ${LASTFOUNDTOKEN}  --debug --output text 2>>${FILE}.${COUNTER}.debug >> ${FILE}.${COUNTER}
	LASTFOUNDTOKEN=`grep "<Marker>" ${FILE}.${COUNTER}.debug | tail -1 | tr -d "<Marker>" | tr -d "/" | tr -d " "`
	
	echo "LASTFOUNDTOKEN is ${LASTFOUNDTOKEN}"
	echo "PREVIOUSTOKEN is ${PREVIOUSTOKEN}"
	
	if [ ${PREVIOUSTOKEN} == ${LASTFOUNDTOKEN} ]; then
		echo "No more new markers, exiting"
		rm -f ${FILE}.${COUNTER}.debug
		rm -f ${FILE}.${COUNTER}
		break;
	else
		echo "Marker is ${LASTFOUNDTOKEN} more to come ... "
		echo " "
		rm -f ${FILE}.${COUNTER}.debug
		PREVIOUSTOKEN=${LASTFOUNDTOKEN}
	fi
	
	cat ${FILE}.${COUNTER} >> ${FILE}
	rm -f ${FILE}.${COUNTER}
	
	let COUNTER=COUNTER+1
done
#------------log download-------------

#++++++++++++upload log to s3+++++++++++++
aws s3 cp $FILE s3://$BUCKETNAME
#------------upload log to s3-------------

#++++++++++++verify file on s3+++++++++++++
#to be written/optional
#++++++++++++delete local file+++++++++++++
#to be written/optional
#------------delete local file-------------
#------------verify file on s3-------------

#++++++++++++write script log file/status+++++++++++++
#to be written/optional
#++++++++++++write script log file/status+++++++++++++

#++++++++++++uplaod script log file to s3+++++++++++++
#to be written/optional
#++++++++++++delete local file+++++++++++++
#to be written/optional
#------------delete local file-------------
#++++++++++++uplaod script log file to s3+++++++++++++




