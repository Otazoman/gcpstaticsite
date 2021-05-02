#!/bin/bash
cd `dirname $0`
SLEEP_TIME=30
HTTP_STATUS_CODE=200

if [ $# != 1 ]; then
    echo "Empty Domain! Please [./create_stacks.sh example.com]"
    exit 1
fi
domain=$1
sitename=${domain/./-}

cp yaml/static-site-create.yaml yaml/${sitename}-static-site-create.yaml
#sed -i -e "s/SITENAME/${sitename}/g" yaml/${sitename}-static-site-create.yaml
#sed -i -e "s/DOMAIN/${domain}/g" yaml/${sitename}-static-site-create.yaml
sed -i -e "s/SITENAME/${sitename}/g" -e "s/DOMAIN/${domain}/g" yaml/${sitename}-static-site-create.yaml

echo "*** Deploymentmanager Run ***"
gcloud deployment-manager deployments create ${sitename}-static-site-deployment --config yaml/${sitename}-static-site-create.yaml

echo "*** dnssec on ***"
gcloud dns managed-zones update  ${sitename}-dnszone --dnssec-state on

echo "*** Web Sit Setting ***"
gsutil rsync -R ~/html/dist/ gs://site-${sitename}
gsutil iam ch allUsers:objectViewer gs://site-${sitename}
gsutil web set -m index.html -e 404.html gs://site-${sitename}

echo "*** Please Setting Your Domain Nameserver ***"
ns_records=$(gcloud dns record-sets list \
        --zone="${sitename}-dnszone" \
        --name="${domain}" \
        --type="NS" \
        | grep -oP "ns-cloud-[0-9a-zA-Z?=#+_&:/.%]+")
array=(${ns_records//$'\n'/ })
for i in ${array[@]}
do
  echo ${i}
done
echo "*** http statuscode check ***"
while true
do
   echo "Check now please wait・・・"
   sleep ${SLEEP_TIME}
   naked_code=$(echo $(curl -s https://${domain} -o /dev/null -w "%{http_code}\n"))
   www_code=$(echo $(curl -s https://www.${domain} -o /dev/null -w "%{http_code}\n"))
   if [ "$naked_code" -eq "$HTTP_STATUS_CODE" ] && [ "$www_code" -eq "$HTTP_STATUS_CODE" ]; then
      break
   fi
done
echo "*** Setting Complete ***"
