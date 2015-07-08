#!/bin/bash
# @author nanopx

# build image
echo "Building docker image..."
docker build -t nanopx/aws_env_s3_sqs_dynamodb .

# remove previous containers if exist
echo "Removing initialized container..."
docker stop aws-local-env 1>/dev/null 2>/dev/null && docker rm aws-local-env 1>/dev/null 2>/dev/null && echo "Removed initialized container." || echo "Container not initialized. No need to remove."

# run container
echo "Running docker image..."
docker run -d -p 8080:8080 -p 8000:8000 -p 9324:9324 --name="aws-local-env" nanopx/aws_env_s3_sqs_dynamodb
