#!/bin/bash
set -e
dir=`dirname $0`
key_bits=1024
expire_days=36500
subj=/C="CN"/ST="ZJ"/L="HZ"/O="Cryptape"/OU="cita"/CN="cita"
sub_subj=/C="CN"/ST="ZJ"/L="HZ"/O="Cryptape"/OU="cita"/CN="test-chain%s.cita"

key="key"
csr="csr"
crt="crt"
pfx="server.pfx"
rootca="root"
conf="ca.conf"
crl="crl.pem"
base="baseroot"
password="server.tls.cita"
days=36500
COMMAND=$1

if [ $# -lt 1 ];then
    echo "input your nodes you wanted\n"
    echo "like this: ./gen_ca.sh create 0 1 2 3"
    echo "like this: ./gen_ca.sh revoke 0 1"
    echo "like this: ./gen_ca.sh verify 0 1"
    exit 0
fi

create() {
	mkdir -p ca_files
	cd ca_files

	cp -f ../$conf ./
	if [ ! -f "serial" ]; then
		echo 01 > serial
	fi
	if [ ! -f "crlnumber" ]; then
		echo 01 > crlnumber
	fi
	touch index.txt

	if [ ! -f $rootca.$key ]||[ ! -f $rootca.$crt ] ;then
	    openssl req -newkey rsa:$key_bits -nodes  -keyout $rootca.$key -days $days -x509 -out $rootca.$crt -subj $subj
	    cp -f ${rootca}.$crt ${base}.$crt
	fi

	for node in "${@:2}"
	do
	mkdir -p $node
	
	node_subj=$(printf $sub_subj $node)
	openssl genrsa -out ${node}.$key $key_bits
	openssl req -new -key ${node}.$key -days $days -out ${node}.$csr -subj ${node_subj}

	openssl ca -batch -config $conf -notext -in ${node}.$csr -out ${node}.$crt

	openssl pkcs12 -export -out ${node}/${pfx} -inkey $node.$key -in $node.$crt -chain -CAfile $rootca.$crt -password pass:${password}

	cp $node.* $node/ 
	cp -f $rootca.$crt ./$node

	#openssl req -newkey rsa:$key_bits -nodes -keyout ${node}.$key -days $days -out ${node}.$csr -subj ${node_subj}
	#openssl x509 -CAcreateserial -req -in ${node}.$csr -CA $rootca.$crt -CAkey $rootca.$key -out $node.$crt -days $days
	#openssl pkcs12 -export -in $node.$crt -inkey $node.$key -out ${node}/${pfx} -password pass:${password}
	#rm -f ${node}.$key $node.$crt ${node}.$csr
	done
	openssl ca -config $conf -gencrl -keyfile $rootca.$key -cert $rootca.$crt -out $crl
	
	cat $crl >> ${rootca}.$crt
}

revoke() {
	cd ca_files
	for node in "${@:2}"
	do
		openssl ca -config $conf -revoke $node/$node.$crt -keyfile $rootca.$key -cert $rootca.$crt 
	done
	openssl ca -config $conf -gencrl -keyfile $rootca.$key -cert $rootca.$crt -out $crl
	echo > ${rootca}.$crt
	cat $base.$crt $crl > ${rootca}.$crt
}

verify() {
	cd ca_files
	for node in "${@:2}"
	do
		echo `openssl verify -crl_check -CAfile $rootca.$crt $node/$node.$crt`
	done
}


case "${COMMAND}" in
    create)
	 create $@
	 exit 0
        ;;
    revoke)
	 revoke $@
	 exit 0
        ;;
     verify)
	 verify $@
	 exit 0
        ;;
esac


