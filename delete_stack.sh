#!/bin/bash

cd `dirname $0`

if [ $# != 1 ]; then
    echo 'Empty Domain! Please [./deletestack.sh example.com]'
    exit 1
fi
domain=$1
sitename=${domain/./-}

gsutil rm gs://site-${sitename}/**

echo '*** Delete Stack ***'
gcloud deployment-manager deployments delete ${sitename}-static-site-deployment
rm yaml/${sitename}-static-site-create.yaml
