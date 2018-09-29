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
if [ ! $PORTNUMBER ] ; then PORTNUMBER="2282"; fi 
if [ ! $NODEIP ] ; then NODEIP="192.168.1.41"; fi 
if [ ! $WALLETURL ] ; then WALLETURL="wallet"; fi 

HOMEPROG="${HOME}/.wallet_balancer"
mkdir -p ${HOMEPROG} 
LASTWALLET="${HOMEPROG}/lastwallet.dat"
HEAD_URL='curl  --connect-timeout 1  -f -s -H "Content-Type: application/json" -X POST -d '{\"method\":\"getAddresses\",\"id\":\"0\",\"jsonrpc\":\"2.0\",\"params\":{}}' http://'
COUNTADDRS=""
if [ ! -e ${LASTWALLET} ] ; then  
        echo not found ${LASTWALLET}
#       echo "${HEAD_URL}${NODEIP}:${PORTNUMBER}/${WALLETURL} | jq  '.result.addresses | length'  "
        INITLAST_RESULT=` ${HEAD_URL}${NODEIP}:${PORTNUMBER}/${WALLETURL}  | jq  '.result' `                   
        _CHKINIT=$?
        INITLAST=$( echo $INITLAST_RESULT  | jq  '.addresses | length' )
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
else 
   # Find missing
   MISSING=$( echo $NEWNUMBER - $LASTNUMBER | bc ) 
   if [ ${MISSING} -ge 1 ] ; then 
       LOWESTMISSING=$( echo  ${NEWNUMBER} - ${MISSING} + 1  | bc  ) ;
       echo ======= GO ADD MISSING IS ${LOWESTMISSING} GO ADD DB =====
       WALLETINDEX=$( echo ${LOWESTMISSING} - 1 | bc ) 
       GETNEW_WALLET=$( ${HEAD_URL}${NODEIP}:${PORTNUMBER}/${WALLETURL}  | jq  .result.addresses[${WALLETINDEX}] | tr '"' ' ' | awk '{$1=$1;print}' )
       GET_SPENDKEY=` curl  --connect-timeout 1  -f -s -H "Content-Type: application/json" -X POST \
       --data "{\"method\":\"getSpendKeys\",\"id\":\"test\",\"jsonrpc\":\"2.0\",\"params\":{\"address\":\"${GETNEW_WALLET}\"  }}" \
           http://${NODEIP}:${PORTNUMBER}/${WALLETURL}  | jq -r '.result.spendSecretKey'  ` 
        echo [ PUBLIC KEY:${GETNEW_WALLET}:${GET_SPENDKEY}:   ]
       if [ ${GETNEW_WALLET} ] && [ ${GET_SPENDKEY} ] ; then 
         :
         
         echo PUBKEY: ${GETNEW_WALLET}  SPEND KEY: ${GET_SPENDKEY} 
         echo $LOWESTMISSING  > ${LASTWALLET}
       else
         :
         echo  NODATA
       fi
       
   fi
fi


sleep 1 
done
