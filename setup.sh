#!/bin/bash


# Basic config
postconf -e myhostname=${PFX_MYHOSTNAME}
postconf -e mynetworks=${PFX_MYNETWORKS}
postconf -e inet_protocols=ipv4

# TLS
certdir=/etc/postfix/certs
if [[ ! -f ${certdir}/host.pem ]]
then
  openssl req -subj "/CN=${PFX_MYHOSTNAME}" -newkey rsa:4096 -nodes -sha512 -x509 -days 3650 -nodes -out ${certdir}/cert.pem -keyout ${certdir}/key.pem
  
  cat ${certdir}/key.pem   >${certdir}/host.pem
  cat ${certdir}/cert.pem >>${certdir}/host.pem
  
  chown postfix:root ${certdir}/*.pem
  chmod 0400 ${certdir}/*.pem
fi

if [[ ! -f ${certdir}/host.pem ]]
then
  echo "TLS cert not found"
  exit 1
fi

#postconf -e smtpd_tls_chain_files=${certdir}/host.pem 
postconf -e smtpd_tls_cert_file=${certdir}/cert.pem
postconf -e smtpd_tls_key_file=${certdir}/key.pem
postconf -M smtps/inet="smtps    inet  n       -       n       -       -       smtpd -o smtpd_tls_wrappermode=yes -o smtpd_sasl_auth_enable=yes"


# DKIM
postconf -e milter_protocol=2
postconf -e milter_default_action=accept
postconf -e smtpd_milters=inet:localhost:8892
postconf -e non_smtpd_milters=inet:localhost:8892

# The selector
hh=${PFX_MYHOSTNAME%%.*}

# Initialize configure files
:>/etc/postfix/opendkim/signing.table
:>/etc/postfix/opendkim/key.table 
:>/etc/postfix/opendkim/trusted.hosts

# Loop for domains
for dd in ${PFX_MYHOSTNAME#*.} ${PFX_DKIMDOMAINS}
do

  # Add domain to configure file
  cat >>/etc/postfix/opendkim/signing.table <<END
*@${dd}    ${hh}._domainkey.${dd}
END

  cat >>/etc/postfix/opendkim/key.table <<END
${hh}._domainkey.${dd}     ${dd}:${hh}:/etc/postfix/opendkim/keys/${dd}/${hh}.private
END

  cat >>/etc/postfix/opendkim/trusted.hosts <<END
127.0.0.1
localhost
*.${dd}
::1
END

  # Generate key if not exists
  if [[ ! -d /etc/postfix/opendkim/${dd} ]]
  then
    mkdir -p /etc/postfix/opendkim/keys/${dd}
    opendkim-genkey -d ${dd} -D /etc/postfix/opendkim/keys/${dd} -s ${hh} -v

    chown -v -R opendkim:opendkim /etc/postfix/opendkim 
    chmod 0600 /etc/postfix/opendkim/keys/${dd}/*.private

    echo "Public key for ${dd}:"
    cat /etc/postfix/opendkim/keys/${dd}/${hh}.txt
    echo
  fi
done




