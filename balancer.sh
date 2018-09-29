#!/bin/bash
for i in "$@"
do
case $i in
    -d=*|--debug=*)
    DEBUG="${i#*=}"
    shift
    ;;
    -p=*|--PUBKEY=*)
    PUBKEY="${i#*=}"
    shift
    ;;
    -n=*|--PORTNUMBER=*)
    PORTNUMBER="${i#*=}"
    shift
    ;;
    -w=*|--WALLETURL=*)
    WALLETURL="${i#*=}"
    shift
    ;;
    -i=*|--NODEIP=*)
    NODEIP="${i#*=}"
    shift
    ;;
    *)

esac
done

if [ ! $DEBUG ] ; then DEBUG="on" ; fi 
if [ ! $PUBKEY ] ; then :  ; fi 
if [ ! $PORTNUMBER ] ; then PORTNUMBER="9559"; fi 
if [ ! $NODEIP ] ; then NODEIP="127.0.0.1"; fi 
if [ ! $WALLETURL ] ; then WALLETURL="wallet"; fi 

HOMEPROG="${HOME}/.wallet_balancer"
mkdir -p ${HOMEPROG} 
LASTWALLET="${HOMEPROG}/lastwallet.dat"
HEAD_URL='curl  --connect-timeout 1  -f -s -H "Content-Type: application/json" -X POST -d '{\"method\":\"getAddresses\",\"id\":\"0\",\"jsonrpc\":\"2.0\",\"params\":{}}' http://'
COUNTADDRS=""
if [ ! -e ${LASTWALLET} ] ; then  
        echo not found ${LASTWALLET}
#       echo "${HEAD_URL}${NODEIP}:${PORTNUMBER}/${WALLETURL} | jq  '.result.addresses | length'  "
        #INITLAST=`   ${HEAD_URL}${NODEIP}:${PORTNUMBER}/${WALLETURL} | jq  '.result.addresses | length' ` 
        INITLAST=` ${HEAD_URL}${NODEIP}:${PORTNUMBER}/${WALLETURL}  | jq  '.result.addresses | length' ` 
        _CHKINIT=$?
        if [ $_CHKINIT -eq 0 ] ; then 
               echo $INITLAST > $LASTWALLET 
               echo === START BY NUMBER $INITLAST ==
        else 
                echo API CONNECTION ERROR START AGAIN ! 
                exit 1
        fi             
        COUNTADDRS=$( cat ${LASTWALLET} )  ; 
fi

while true
do
:
LASTNUMBER=$( cat ${LASTWALLET} ) ;
NEWNUMBER=$( ${HEAD_URL}${NODEIP}:${PORTNUMBER}/${WALLETURL} | jq -r '.result.addresses | length'   )
_FINDNEW=$?

if [ $(echo $NEWNUMBER - $LASTNUMBER | bc ) -eq 0 ] && [ $_FINDNEW -eq 0 ]  ; then
:
echo "NO NEW WALLET FROM Lastnumber : LASTNUMBER $LASTNUMBER" 
fi


sleep 10
done

COUNTADDRS=$( ${HEAD_URL}${NODEIP}:${PORTNUMBER}/${WALLETURL} | jq -r '.result.addresses | length'   ) 
ADDRESSES=$(  ${HEAD_URL}${NODEIP}:${PORTNUMBER}/${WALLETURL}  ) ;

echo ${HEAD_URL}${NODEIP}:${PORTNUMBER}/${WALLETURL}
echo $ADDRESSES
