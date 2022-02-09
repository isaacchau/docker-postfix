# docker-postfix
A docker image of postfix + smtp auth + dkim

## Environment

1.  **PFX_MYHOSTNAME**
  - use as 'myhostname' for postfix
  - use as CN for the SSL cert for smtpd
  - the domain part will be appended to smtp user name
  - the domain part will be used as the domain of dkim
  - the first part will be used as the selector of dkim
  
    Example: **PFX_MYHOSTNAME=smtp.mydomain.com**
    
    postfix myhostname = smtp.mydomain.com
    
    CN of SSL = smtp.mydomain.com
    
    dkim will sign mail for domain '@mydomain.com' using selector 'smtp'
    
   
  

2.  **PFX_SMTPUSERS**
  - in the format of username:password
  - seperate user by space
  - when login smtp, need to use "username@mydomain.com"

    Example: **PFX_SMTPUSERS=user1:passwd1 user2:passwd2**
    
   
   
3.  **PFX_DKIMDOMAINS**
  - addition domain for dkim to sign
  - dkim selector will be the same as the one derived from PFX_MYHOSTNAME

    Example: **PFX_DKIMDOMAINS=anotherdomain.org**
   
 



## Reference
- https://www.linuxbabe.com/mail-server/setting-up-dkim-and-spf
- https://www.digitalocean.com/community/tutorials/how-to-install-and-configure-dkim-with-postfix-on-debian-wheezy
- http://www.postfix.org/SASL_README.html
- https://docs.docker.com/engine/reference/builder/
