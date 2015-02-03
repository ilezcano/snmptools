#!/bin/bash

SNMPGETNEXT=`which snmpgetnext`
SNMPGET=`which snmpget`

ROUTER=$1
COMM=$2
ADDR=$3
IPNETTOMEDIATABLE=".1.3.6.1.2.1.4.22.1.2"
INTINDEX=0
PHY=0

REGEX="^($IPNETTOMEDIATABLE\.([0-9]+)\.($ADDR)) = (.*)$"
OUTPUT=`$SNMPGETNEXT -OQ -On -v 2c -c $COMM $ROUTER $IPNETTOMEDIATABLE`
#OUTPUT=$IPNETTOMEDIATABLE


while [[ $OUTPUT =~ ^$IPNETTOMEDIATABLE ]]; do
	if [[ $OUTPUT =~ $REGEX ]]; then
		INTINDEX=${BASH_REMATCH[2]}
		PHY=${BASH_REMATCH[4]}
		echo "Found the interface index which is $INTINDEX"
		echo "Found physical address which is $PHY"
		OUTPUT="OUTAHERE"
	else
		[[ $OUTPUT =~ ^(.*)[[:space:]]\= ]]
		OUTPUT=`$SNMPGETNEXT -OQ -On -v 2c -c $COMM $ROUTER ${BASH_REMATCH[1]}`
	fi
done

IFDESC=".1.3.6.1.2.1.2.2.1.2"
IFALIAS=".1.3.6.1.2.1.31.1.1.1.18"


INTDESC=`$SNMPGET -OQ -OU -Ov -v 2c -c $COMM $ROUTER $IFDESC.$INTINDEX`
INTALIAS=`$SNMPGET -OQ -OU -Ov -v 2c -c $COMM $ROUTER $IFALIAS.$INTINDEX`
echo "The description on the layer 3 interface is \"$INTDESC\""
echo "The alias on the layer 3 interface is \"$INTALIAS\""


if [[ $PHY ]]; then

	echo "Trying MAC table logic"
	DOT1DPORT=".1.3.6.1.2.1.17.4.3.1.2"
	OFS=$IFS

	IFS=':' read -a HEXARRAY <<< "$PHY"

	for X in "${HEXARRAY[@]}"
	do
		HEXOID+=".$((16#$X))"
	done

	LTWOINDEX=`$SNMPGET -OQ -OU -Ov -v 2c -c $COMM $ROUTER $DOT1DPORT$HEXOID`
	INTDESC=`$SNMPGET -OQ -OU -Ov -v 2c -c $COMM $ROUTER $IFDESC.$LTWOINDEX`
	INTALIAS=`$SNMPGET -OQ -OU -Ov -v 2c -c $COMM $ROUTER $IFALIAS.$LTWOINDEX`
	echo "The description on the layer 2 interface is \"$INTDESC\""
	echo "The alias on the layer 2 interface is \"$INTALIAS\""
fi
