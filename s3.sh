#!/usr/bin/env bash

# This script will create the S3 IAM user, generate IAM keys & generate user policy.

ts=$(date +%Y-%m-%d)
s3bucketname="MY-S3-BUCKET"
region="eu-central-1"

function check_command {
	type -P $1 &>/dev/null || fail "Unable to find $1, please install it and run this script again."
}

function fail(){
	tput setaf 1; echo "Failure: $*" && tput sgr0
	exit 1
}

if ! grep -q aws_access_key_id ~/.aws/config; then
  if ! grep -q aws_access_key_id ~/.aws/credentials; then
    echo "AWS config not found or CLI not installed. Please run \"aws configure\"."
    exit 1
  fi
fi

check_command "aws"

if [ "$s3bucketname" = "MY-S3-BUCKET" ]; then
	read -r -p "Enter S3 Bucket Name: " s3bucketname
fi
if [ -z "$s3bucketname" ]; then
	fail "S3 Bucket Name must be set."
fi

echo "Creating bucket $s3bucketname"
aws s3 mb s3://$s3bucketname --region $region

read -r -p "Enter the client name: " client
echo "Creating IAM User: "s3-$client
aws iam create-user --user-name s3-$client
echo "Generating IAM Access Keys"
aws iam create-access-key --user-name s3-$client


cat > userpolicy.json << EOF
{
    "Version": "$ts",
    "Statement": [
        {
            "Sid": "AllowListObjects",
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket"
            ],
            "Resource": "arn:aws:s3:::$s3bucketname"
        },
        {
            "Sid": "AllowObjectsCRUD",
            "Effect": "Allow",
            "Action": [
                "s3:DeleteObject",
                "s3:GetObject",
                "s3:PutObject"
            ],
            "Resource": "arn:aws:s3:::$s3bucketname/*"
        }
    ]
}
EOF

echo "Generating User Policy"
aws iam put-user-policy --user-name s3-$client --policy-name $client-s3-buckets --policy-document file://userpolicy.json
rm userpolicy.json
echo "Completed!"
