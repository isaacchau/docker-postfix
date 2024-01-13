#!/bin/bash

echo "Start execute ${0}"

chown -Rv syslog:syslog /var/log
chmod 2775 /var/log

if [[ ! -f /etc/postfix/.setup_complete ]]
then
  if ! cp -frpv /opt/postfix/* /etc/postfix/ 
  then
    echo "Failed copy /etc/postfix"
    exit 1
  fi
  
  if ! bash /opt/setup.sh
  then
    echo "Failed execute setup.sh"
    exit 1
  fi
  
  touch /etc/postfix/.setup_complete
fi


# SMTP AUTH
if [[ -n "${PFX_SMTPUSERS}" ]]
then
  
  cat >/etc/postfix/sasl/smtpd.conf <<EOF
pwcheck_method: auxprop
auxprop_plugin: sasldb
mech_list: PLAIN LOGIN CRAM-MD5 DIGEST-MD5 NTLM
sasldb_path: /etc/postfix/sasl/sasldb2
EOF

  rm -f /etc/postfix/sasl/sasldb2
  for smtpuser in ${PFX_SMTPUSERS}
  do
    uu=$(echo "${smtpuser}" | cut -f1 -d: )
    pp=$(echo "${smtpuser}" | cut -f2 -d: )
    dd=$(postconf -h mydomain)
    if echo "${uu}" | grep -q -Pie "@\S\.\S"
    then
      dd=$(echo "${uu}" | cut -f2 -d\@)
      uu=$(echo "${uu}" | cut -f1 -d\@)
    fi
      
    echo "${pp}" | saslpasswd2 -p -f /etc/postfix/sasl/sasldb2 -c -u "${dd}" "${uu}"
  done
  chown postfix:sasl /etc/postfix/sasl/sasldb2 
  sasldblistusers2 -f /etc/postfix/sasl/sasldb2 
    
  postconf -e smtpd_sasl_auth_enable=yes
  postconf -e smtpd_recipient_restrictions=permit_sasl_authenticated,reject_unauth_destination
    
else
  echo "No SMTP user defined"
fi

ls -lr /var/log

# Start postfix
service rsyslog restart
service opendkim restart
chmod o+r /var/log/*

rm -f /var/spool/postfix/pid/master.pid
exec /usr/sbin/postfix -c /etc/postfix start-fg
