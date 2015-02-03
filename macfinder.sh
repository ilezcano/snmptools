#!/bin/bash

SNMPGET=`which snmpget`

ROUTER=$1
COMM=$2
MADDR=$3
DOT1DPORT=".1.3.6.1.2.1.17.4.3.1.2"
IFDESC=".1.3.6.1.2.1.2.2.1.2"
IFALIAS=".1.3.6.1.2.1.31.1.1.1.18"


echo "Trying MAC table logic"
OFS=$IFS

IFS=':' read -a HEXARRAY <<< "$MADDR"

for X in "${HEXARRAY[@]}"
do
	HEXOID+=".$((16#$X))"
done

LTWOINDEX=`$SNMPGET -OQ -OU -Ov -v 2c -c $COMM $ROUTER $DOT1DPORT$HEXOID`
INTDESC=`$SNMPGET -OQ -OU -Ov -v 2c -c $COMM $ROUTER $IFDESC.$LTWOINDEX`
INTALIAS=`$SNMPGET -OQ -OU -Ov -v 2c -c $COMM $ROUTER $IFALIAS.$LTWOINDEX`
echo "The description on the layer 2 interface is \"$INTDESC\""
echo "The alias on the layer 2 interface is \"$INTALIAS\""
