FROM ibmcom/websphere-traditional:latest
USER root
RUN apt-get update
RUN apt-get install -y vim
RUN apt-get install -y sudo
RUN echo 'was ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
USER was
