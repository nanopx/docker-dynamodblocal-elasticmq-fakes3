###
FROM java
MAINTAINER nanopx <0nanopx@gmail.com>
#
# Dockerfile for creating a development environment for DynamoDB, SQS and S3
#   - ElasticMQ (for SQS)
#
#   - DynamoDBlocal (for DynamoDB)
#       https://aws.amazon.com/blogs/aws/dynamodb-local-for-desktop-development/
#
#   - fake-s3 (for S3)
#
# https://github.com/nanopx/docker-dynamodblocal-elasticmq-fakes3
###

# Port for fake-s3
ENV FAKES3_PORT 8080
# Port for DynamoDB
ENV DYNAMODB_PORT 8000
# Port for ElasticMQ
ENV ELASTICMQ_PORT 9324
# Version of ElasticMQ
ENV ELASTICMQ_VERSION elasticmq-server-0.8.8

# Update apt-get
RUN apt-get update && apt-get -y upgrade

# Install dependencies
RUN apt-get install -y sudo net-tools apt-utils wget curl tar ruby

# Install supervisord
RUN apt-get install -y supervisor

# Mount supervisord configuration
ADD config/supervisord/supervisord.conf /etc/supervisord.conf

# Clean cache files
RUN apt-get clean && rm -rf /var/cache/apt/archives/* /var/lib/apt/lists/*

# install fake-s3
RUN gem install fakes3 --no-ri --no-rdoc

# run fake-s3
RUN mkdir -p /fakes3_root
# ENTRYPOINT ["fakes3"]
# CMD ["-r",  "/fakes3_root", "-p",  $FAKES3_PORT]
EXPOSE $FAKES3_PORT
# Add VOLUMEs to store images
VOLUME ["/var/s3_local", "/fakes3_root"]

# install ElasticMQ
WORKDIR /elasticmq
RUN wget https://s3-eu-west-1.amazonaws.com/softwaremill-public/$ELASTICMQ_VERSION.jar -O elasticmq-server.jar
COPY /config/elasticmq/custom.conf /elasticmq/custom.conf
COPY /config/elasticmq/logback.xml /elasticmq/logback.xml

# run elasticmq
# ENTRYPOINT ["java", "-Dconfig.file=/elasticmq/custom.conf", "-Dlogback.configurationFile=/elasticmq/logback.xml", "-jar", "/elasticmq/elasticmq-server.jar"]
EXPOSE $ELASTICMQ_PORT

# Create working space and fetch DynamoDBlocal
RUN mkdir /var/dynamodb_wd
# WORKDIR /var/dynamodb_wd
RUN wget -O /var/dynamodb_wd/dynamodb_local_latest http://dynamodb-local.s3-website-us-west-2.amazonaws.com/dynamodb_local_latest
RUN tar xfz /var/dynamodb_wd/dynamodb_local_latest

# Default command for image
# ENTRYPOINT ["/usr/bin/java", "-Djava.library.path=.", "-jar", "DynamoDBLocal.jar", "-dbPath", "/var/dynamodb_local"]
# CMD ["-port", $DYNAMODB_PORT]

# expose port for DynamoDBlocal
EXPOSE $DYNAMODB_PORT

# Add VOLUMEs to allow backup of config, logs and databases
VOLUME ["/var/dynamodb_local", "/var/dynamodb_wd"]

# Initialize supervisord
CMD /usr/bin/supervisord -c /etc/supervisord.conf
