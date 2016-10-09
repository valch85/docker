############################################################
# Dockerfile to build Nginx Installed Containers
# Based on Ubuntu
############################################################

# Set the base image to Ubuntu
FROM ubuntu:latest

MAINTAINER Valentyn Chubukin <val@valch.name>

# Install Nginx

# Add application repository URL to the default sources
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys ABF5BD827BD9BF62
RUN echo "deb http://nginx.org/packages/ubuntu/ xenial nginx" >> /etc/apt/sources.list


# Update the repository
RUN apt-get update

# Install necessary tools
#RUN apt-get install -y wget dialog net-tools

# Download and Install Nginx
RUN apt-get install -y nginx    

# forward request and error logs to docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log
RUN ln -sf /dev/stderr /var/log/nginx/error.log

# Remove the default Nginx configuration file
RUN rm -v /etc/nginx/nginx.conf

# Copy a configuration file from the current directory
COPY nginx.conf /etc/nginx/nginx.conf
COPY blog.conf /etc/nginx/conf.d/default.conf

VOLUME ["/var/cache/nginx"]

# Expose ports
EXPOSE 80 443

# Set the default command to execute
# when creating a new container
CMD service nginx start