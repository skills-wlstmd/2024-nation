#!/bin/bash
containers=$(docker ps -aq)
if [ -n "$containers" ]; then
    for container_id in $containers; do
        docker stop $container_id
        docker rm $container_id
    done
else
    echo "No containers to stop or remove."
fi

rm -rf /home/ec2-user/*