FROM ubuntu:14.04

MAINTAINER Usability Dynamics, Inc. "http://usabilitydynamics.com"

RUN export DEBIAN_FRONTEND=noninteractive && \
    apt-get update && \
    apt-get install -y python-software-properties software-properties-common
RUN export DEBIAN_FRONTEND=noninteractive && \
    add-apt-repository -y ppa:gluster/glusterfs-3.5 && \
    apt-get update && \
    apt-get install -y glusterfs-server supervisor openssh-server

ENV GLUSTER_PEERS 10.86.76.254,10.107.97.236
ENV SSH_PORT 2222
ENV SSH_OPTS ["-p ${SSH_PORT} -o ConnectTimeout=4 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"]
ENV GLUSTER_VOL storage
ENV GLUSTER_BRICK_PATH /gluster/${GLUSTER_VOL}
ENV DEBUG 0

VOLUME ["/gluster/${GLUSTER_VOL}"]

EXPOSE ${SSH_PORT}
EXPOSE 24007
EXPOSE 24008
EXPOSE 24009
EXPOSE 49152
EXPOSE 111
EXPOSE 111/udp

RUN mkdir -p /var/run/sshd /root/.ssh /var/log/supervisor
RUN perl -p -i -e "s/^Port .*/Port ${SSH_PORT}/g" /etc/ssh/sshd_config
RUN perl -p -i -e "s/#?PasswordAuthentication .*/PasswordAuthentication no/g" /etc/ssh/sshd_config
RUN perl -p -i -e "s/#?PermitRootLogin .*/PermitRootLogin yes/g" /etc/ssh/sshd_config
RUN grep ClientAliveInterval /etc/ssh/sshd_config >/dev/null 2>&1 || echo "ClientAliveInterval 60" >> /etc/ssh/sshd_config
ADD ./ssh /root/.ssh
RUN chmod -R g-rwx,o-rwx /root/.ssh

RUN mkdir -p /usr/local/bin
ADD ./bin /usr/local/bin
RUN chmod +x /usr/local/bin/*.sh
ADD ./etc/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

CMD ["/usr/local/bin/run.sh"]
