FROM ubuntu:16.04

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.UTF-8 \
    TERM=xterm
RUN echo "export > /etc/envvars" >> /root/.bashrc && \
    echo "export PS1='\e[1;31m\]\u@\h:\w\\$\[\e[0m\] '" | tee -a /root/.bashrc /etc/bash.bashrc && \
    echo "alias tcurrent='tail /var/log/*/current -f'" | tee -a /root/.bashrc /etc/bash.bashrc

RUN apt-get update
RUN apt-get install -y locales && locale-gen en_US en_US.UTF-8

# Runit
RUN apt-get install -y --no-install-recommends runit
CMD export > /etc/envvars && /usr/sbin/runsvdir-start

# Utilities
RUN apt-get install -y --no-install-recommends vim less net-tools inetutils-ping wget curl git telnet nmap socat dnsutils netcat tree htop unzip sudo software-properties-common jq psmisc iproute python ssh rsync

#Install Oracle Java 8
RUN add-apt-repository ppa:webupd8team/java -y && \
    apt-get update && \
    echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections && \
    apt-get install -y oracle-java8-installer && \
    apt install oracle-java8-unlimited-jce-policy && \
    rm -r /var/cache/oracle-jdk8-installer
ENV JAVA_HOME /usr/lib/jvm/java-8-oracle

#Wildfly
RUN wget -O - http://download.jboss.org/wildfly/10.1.0.Final/wildfly-10.1.0.Final.tar.gz| tar zx
RUN mv wildfly* wildfly

#Drools Workbench
RUN wget -O /wildfly/standalone/deployments/drools.war https://download.jboss.org/drools/release/6.5.0.Final/kie-drools-wb-6.5.0.Final-wildfly10.war

#Keycloak adapter
RUN cd wildfly && \
    wget -O - https://downloads.jboss.org/keycloak/3.0.0.Final/adapters/keycloak-oidc/keycloak-wildfly-adapter-dist-3.0.0.Final.tar.gz | tar zx
RUN cd wildfly && \
    sed -i -e "s|standalone.xml|standalone-full.xml|" bin/adapter-install-offline.cli && \
    ./bin/jboss-cli.sh --file=bin/adapter-install-offline.cli

# Add runit services
COPY sv /etc/service 
ARG BUILD_INFO
LABEL BUILD_INFO=$BUILD_INFO

