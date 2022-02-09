FROM ubuntu:latest
MAINTAINER Isaac

# Use for:
#  1. Postfix myhostname
#  2. CN for SSL cert
#  3. DKIM "mail" as selector, "yourdomain.com" as domain
ENV PFX_MYHOSTNAME=mail.yourdomain.com

# List on which network interface
ENV PFX_MYNETWORKS=0.0.0.0

# Define user:password pairs for SMTP AUTH
# When login need to use user1@yourdomain.com
# Format: user1:password1 user2:password2  
ENV PFX_SMTPUSERS=""


# Extra domain for DKIM, selector will use the hostname in PFX_MYHOSTNAME
# e.g. PFX_DKIMDOMAINS=anotherdomain.com
ENV PFX_DKIMDOMAINS=

VOLUME /var/log
VOLUME /var/spool/postfix
VOLUME /etc/postfix

RUN apt-get update \
&& echo "postfix postfix/mailname string ${PFX_FQDN}"             | debconf-set-selections \
&& echo "postfix postfix/main_mailer_type string 'Internet Site'" | debconf-set-selections \
&& DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends postfix sasl2-bin libsasl2-modules opendkim opendkim-tools rsyslog \
&& apt clean \
&& gpasswd -a postfix opendkim \
&& cp -pfv /etc/postfix/main.cf /opt/main_cf.tmpl \
&& cp -pfv /etc/postfix/master.cf /opt/master_cf.tmpl \
&& mkdir -p /etc/postfix/certs \
&& mkdir -p /opt/postfix \
&& mkdir -p /etc/postfix/opendkim \
&& mkdir -p /etc/postfix/opendkim/keys \
&& chown -v -R opendkim:opendkim /etc/postfix/opendkim \
&& chmod go-rw /etc/postfix/opendkim/keys \
&& mv -fv /etc/postfix/* /opt/postfix/  \
&& rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* ~/.cache ~/.npm /var/log/*

# Debug
# RUN apt update \
# && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends net-tools netcat lsof vim-tiny curl bsd-mailx \
# && apt-get clean && rm -rf /var/lib/apt/lists/* 


EXPOSE 25/tcp 465/tcp

ADD *.sh /opt/
ADD opendkim.conf /etc/

CMD bash /opt/run.sh
