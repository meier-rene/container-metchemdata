FROM ubuntu:xenial

# install java
RUN apt-get -y update && apt-get install -y openjdk-8-jre wget postgresql git

# add script
ADD scripts /scripts
ADD schema /schema

# hostname:port:database:username:password to ~/.pgpass
CMD echo $POSTGRES_IP:$POSTGRES_PORT:$POSTGRES_DB:$POSTGRES_USER:$POSTGRES_PASSWORD > ~/.pgpass && chmod 600 ~/.pgpass && bash /scripts/main.sh
# CMD echo $POSTGRES_IP:$POSTGRES_PORT:$POSTGRES_DB:$POSTGRES_USER:$POSTGRES_PASSWORD > ~/.pgpass && chmod 600 ~/.pgpass && touch /tmp/test && tail -f /tmp/test
