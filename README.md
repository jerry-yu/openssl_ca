# openssl_ca
use openssl sign certificate and revoke certificate

**ca.conf 
copy from openssl's openssl.cnf in /usr/lib/ssl/,
and modify some params to direct towards current dir

**./cert.sh create 0 1 2 3  
 gennerate 4 certificate in applied directory

**./cert.sh revoke 0 1
revoke 0,1 's certificate

**./cert.sh verify 0 1
verify 0,1 's certificate
