#!/bin/bash

count=0
while [ $count -ne 5 ]
do
  count=$(kubectl get pods --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}' | xargs -n1 kubectl logs | grep -c 'Reporting task end')
  echo "waiting, current count: $count"
  sleep 5
done