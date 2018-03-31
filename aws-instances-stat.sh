#!/bin/bash
# Created By: anirvan
# License: MIT
# CopyWrite: 2018
# Version: 1.0

RED='\033[0;31m' 
NC='\033[0m'  # No Color
GREEN='\033[0;32m' 

#today=`date '+%Y_%m_%d__%H_%M_%S'`
fullfile="aws_instances.json"
filename="${fullfile%.*}"

function isinstalled {
# Installing python and necessary packages locally
pckarr=( gcc python python-devel python-pip nodejs npm )
for i in "${pckarr[@]}"
 do
  isinstalled=$(rpm -q $i)
  if [ !  "$isinstalled" == "package $i is not installed" ];
   then
    echo -e ${GREEN} Package  $i already installed ${NC}
  else
    echo -e ${RED} $i is not INSTALLED!!!! ${NC}
     #yum install $i -y --enablerepo=epel
     yum install $i -y
  fi
done
 echo -e  ${GREEN}  json2html - python module for converting complex JSON oject to HTML Table  ${NC}
     pip install --upgrade pip
     pip install json2html # install json2html
     pip show json2html # to check python module version info
}

function getpy() {
#aws --version
#pip install awscli
aws ec2 describe-instances --region eu-central-1 --query 'Reservations[*].Instances[*].{InstanceId:InstanceId,ImageId:ImageId,KeyName:KeyName,InstanceType:InstanceType,Architecture:Architecture,VirtualizationType:VirtualizationType,State:State.Name,PublicIpAddress:PublicIpAddress,SubnetId:SubnetId,Name:Tags[0].Value,PrivateIpAddress:NetworkInterfaces[0].PrivateIpAddress,RootVolumeId:BlockDeviceMappings[0].Ebs.VolumeId,VpcId:NetworkInterfaces[0].VpcId}' --output json > $fullfile
sed -i 's/null/""/g' $fullfile # eliminate null
if [ -f "$fullfile" ]
  then
     echo  -e ${GREEN} "`readlink -f $fullfile` file found \n convert json data to html using json2html" ${NC}
  /usr/bin/yes | /bin/cp $fullfile $filename.py
# edit the json file to python format
  sed -i '1 i\from json2html import *' $filename.py
  sed -i -e '2s/^/input = /'  \
         -e "\$aoutput = json2html.convert(json = input)"  \
         -e "\$aprint output" $filename.py
  sleep 3
  /usr/bin/python $filename.py > index.html
  echo "<p><script> document.write(new Date().toLocaleDateString()); </script></p>" >> index.html
  if [ $? -eq 0 ]; then echo -e ${GREEN} "success!" ${NC} ; fi
else
      echo -e ${RED} "Error: $file file not found." ${NC}
  exit 1
fi
}

function launchapp() {
if [ -f server.js ]
  then
     echo -e ${GREEN} "starting app!" ${NC}
else
cat << EOF > server.js
var http = require('http'),
    fs = require('fs');

fs.readFile('./index.html', function (err, data) {
    if (err) {
        throw err;
    }
    http.createServer(function(request, response) {
        response.writeHeader(200, {"Content-Type": "text/html"});
        response.write(data);
        response.end();
    }).listen(8080);
   console.log('\x1b[36m%s\x1b[0m', 'Server running on 8080...quit with ctrl+C');
});
EOF
fi
# start node js to put our changes into effect
sleep 3
node server.js 2> stderr.txt
}

function cleanup() {
[ -e $filename.py ] && rm $filename.py
[ -e server.js ] && rm server.js
}


cleanup
isinstalled
getpy
launchapp
