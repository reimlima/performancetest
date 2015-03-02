#!/bin/bash

#[ Script ]--------------------------------------------------------------------#
#                                                                              #
# phantomjs.sh                                                                 #
#                                                                              #
# PT-br:                                                                       #
# Script  que coleta informacoes de velocidade de carregamento de varios sites #
# definidos no arquivo phantomjs.conf                                          #
#                                                                              #
# ----------------------------                                                 #
#                                                                              #
# EN:                                                                          #
# Script  that  collect load speed information from a list of websites defined #
# in phantomjs.conf file.                                                      #
#                                                                              #
# reimlima@gmail.com                                                           #
# $Id: phantomjs.sh,v 2 2015/03/02 reimlima Exp reimlima $                     #
#                                                                              #
#[ License ]-------------------------------------------------------------------#
#                                                                              #
# Copyright (c) 2015 Reinaldo Marques de Lima reimlima@gmail.com               #
#                                                                              #
# PT-br:                                                                       #
# A permissão  é  concedida,  a título gratuito, a qualquer pessoa que obtenha #
# uma   cópia   deste   software   e   arquivos   de  documentação  associados #
# (o "Software"),  para  lidar  com  o  Software sem restrição, incluindo, sem #
# limitação,  os  direitos  de  usar,  copiar,  modificar,  mesclar, publicar, #
# distribuir,  sublicenciar,  e / ou vender cópias do Software, e permitir que #
# as  pessoas  a  quem  o  Software  é fornecido o façam, sujeito às seguintes #
# condições:                                                                   #
#                                                                              #
# O  aviso de copyright acima e este aviso de permissão devem ser incluídos em #
# todas as cópias ou partes substanciais do Software.                          #
#                                                                              #
# O  SOFTWARE É FORNECIDO "COMO ESTÁ", SEM GARANTIA DE QUALQUER TIPO, EXPRESSA #
# OU  IMPLÍCITA,  INCLUINDO,  SEM  LIMITAÇÃO, AS GARANTIAS DE COMERCIALIZAÇÃO, #
# ADEQUAÇÃO  A  UM  DETERMINADO  FIM E NÃO VIOLAÇÃO. EM NENHUM CASO OS AUTORES #
# OU  DIREITOS AUTORAIS TITULARES  SERÃO RESPONSÁVEIS POR QUALQUER RECLAMAÇÃO, #
# DANOS  OU  OUTRAS  RESPONSABILIDADES,  SEJA  EM  UMA  AÇÃO DE CUMPRIMENTO DE #
# CONTRATO OU DE OUTRA FORMA, DECORRENTE DE, OU EM CONEXÃO COM O SOFTWARE OU O #
# USO OU OUTRAS FUNÇÕES DO SOFTWARE.                                           #
#                                                                              #
# Exceto  conforme  contido no presente aviso, o nome do (s) dos detentores de #
# direitos  autorais acima não devem ser utilizados em publicidade ou de outra #
# forma  para  promover  a venda, uso ou outras negociações deste Software sem #
# autorização prévia por escrito.                                              #
#                                                                              #
# ----------------------------                                                 #
#                                                                              #
# EN:                                                                          #
# Permission is hereby granted, free of charge, to any person obtaining a copy #
# of  this  software  and  associated  documentation  files  (the "Software"), #
# to  deal  in  the Software without restriction, including without limitation #
# the  rights  to  use,  copy, modify, merge, publish, distribute, sublicense, #
# and/or  sell  copies  of  the  Software,  and  to permit persons to whom the #
# Software is furnished to do so, subject to the following conditions:         #
#                                                                              #
# The  above  copyright notice and this permission notice shall be included in #
# all copies or substantial portions of the Software.                          #
#                                                                              #
# THE  SOFTWARE  IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR #
# IMPLIED,  INCLUDING  BUT  NOT  LIMITED TO THE WARRANTIES OF MERCHANTABILITY, #
# FITNESS  FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE #
# AUTHORS  OR  COPYRIGHT  HOLDERS  BE  LIABLE  FOR ANY CLAIM, DAMAGES OR OTHER #
# LIABILITY,   WHETHER   IN   AN   ACTION  OF  CONTRACT,  TORT  OR  OTHERWISE, #
# ARISING FROM,  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER #
# DEALINGS IN THE SOFTWARE.                                                    #
#                                                                              #
# Except  as  contained  in  this  notice,  the name(s) of the above copyright #
# holders  shall  not be used in advertising or otherwise to promote the sale, #
# use or other dealings in this Software without prior written authorization.  #
#                                                                              #
#[ Changelog ]-----------------------------------------------------------------#
#                                                                              #
# v1   - [01/09/2014] - First release. Only shows informations;                #
# v1.1 - [14/09/2014] - Better json file format optimized for amchart;         #
# v1.2 - [15/10/2014] - Lock file improvements;                                #
# v1.3 - [16/10/2014] - 30 seconds of timeout for phantomjs execution;         #
# v1.4 - [21/10/2014] - Make and update json file defined in JSONFILE;         #
# v2   - [22/01/2015] - Script now work with threads;                          #
# v2.1 - [03/02/2015] - Fix PhantomJS binary validation;                       #
#                                                                              #
#------------------------------------------------------------------------------#

#[ Variables ]-----------------------------------------------------------------#

RM=$(which rm)
AWK=$(which awk)
CAT=$(which cat)
SED=$(which sed)
DATE=$(which date)
GREP=$(which grep)
SCRIPTNAME=$(basename $0)

# script files
SCRIPTCONFFILE="phantomjs.conf"
LOCKFILE=/tmp/${SCRIPTNAME}.lock
FIFOFILE=/tmp/${SCRIPTNAME}.fifo

mkfifo $FIFOFILE &> /dev/null

#[ Functions ]-----------------------------------------------------------------#

trapfunction(){

	# Function called by 'trap' command. Only removes lock
	# file if the process PID was the same in the file.

	PIDOFMYSELF=$$
	PIDINLOCKFILE=$(cat $LOCKFILE)
	if [ "$PIDOFMYSELF" == "$PIDINLOCKFILE" ] ; then
		rm $LOCKFILE
	else
		echo
		echo "PID: $PIDINLOCKFILE"
		echo
	fi
}

trap trapfunction 0 2 3 9 15

exiterrorfunc(){

	# Generic output function, show the message given,
	# and then exits with the given code.

	# Parse message and exit code
	EXITCODE=$(echo $@ | awk '{print $NF}')
	EXITMESSAGE=$(echo $@ | awk '{ $NF = ""; print $0}')
	echo
	echo $EXITMESSAGE
	echo
	exit $EXITCODE
}

threadCollector(){

	# Thread function, for parallel execution

	RESULT=$(timeout 30s $PHANTOMJSBIN $TESTTYPESCRIPT $1 $TESTTYPECONF | $GREP 'Loading' | $AWK '{print $3}')
	if [ -z $RESULT ] ; then
		RESULT="0"
	fi
	echo "\"$2\": \"$RESULT\"" > $FIFOFILE &

}

dataCollector(){

	# Data collection function of url's load time using PhantomJS, tested
	# urls are in phantomjs.conf file.

	if [ $TESTTYPE = "speed" ] ; then
		TESTTYPESCRIPT="$PHANTOMJSFILESDIR/loadspeed.js"
		TESTTYPECONF=""
	else
		exiterrorfunc "INFO: 'performance' function not implemented yet 0"
		#TESTTYPESCRIPT="$PHANTOMJSFILESDIR/confess.js"
		#TESTTYPECONF="$PHANTOMJSFILESDIR/config.json"
	fi

	TESTTIMESTAMP=$($DATE +"%d-%m-%Y %H:%M")
	OUTPUTJSON=$OUTPUTJSON"{\"date\": \"$TESTTIMESTAMP\","
	ELEMENTCOUNT=${#URLARRAY[*]}

	for (( i=0 ; i < $ELEMENTCOUNT ; i++ )); do
		threadCollector ${URLARRAY[$i]} ${SITENAMESARRAY[$i]} &
	done

	wait

	THREADRESULT=$($CAT $FIFOFILE)
	THREADRESULT=$(echo $THREADRESULT| $SED 's/" /", /g')
	OUTPUTJSON="$OUTPUTJSON $THREADRESULT"
	$RM $FIFOFILE

	if [ -e $JSONFILE ] ; then
		$SED -i "s/\(}\) \(\]\)/\1,\n$OUTPUTJSON} \2/" $JSONFILE
	else
		echo "[ $OUTPUTJSON} ]" > $JSONFILE
	fi

	exit 0
}

#[ Load conf file ]------------------------------------------------------------#

if [ -e $SCRIPTCONFFILE ] ; then
	source $SCRIPTCONFFILE
else
	exiterrorfunc "ERROR: phantomjs.conf file not found 1"
fi

#[ tests, tests, tests ]-------------------------------------------------------#

# Validate if there is a lock file
if [ -e $LOCKFILE ]; then
	exiterrorfunc "There is another script running 1"
else
	echo "$$" > $LOCKFILE
fi

# Validate if PhantomJS binary exists
[ -e $PHANTOMJSBIN ] || exiterrorfunc "ERROR: 'phantomjs' not found 1"

# Validate if command line option was given
[ $1 ] || exiterrorfunc "USAGE: $SCRIPTNAME [-s|-p] 1"

# Validate if command line option is valid
[ `echo $1 | sed '/-[sp]/!d'` ] || exiterrorfunc "USAGE: $SCRIPTNAME [-s|-p] 1"

while getopts "sp" opts ; do
        case $opts in
                s) TESTTYPE="speed" ;;
                p) TESTTYPE="performance" ;;
        esac
done

dataCollector $TESTTYPE
