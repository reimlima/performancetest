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
# $Id: phantomjs.sh,v 1.4 2014/09/14 reimlima Exp reimlima $                   #
#                                                                              #
#[ License ]-------------------------------------------------------------------#
#                                                                              #
# Copyright (c) 2014 Reinaldo Marques de Lima reimlima@gmail.com               #
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
# OU  DIREITOS  AUTORAIS  TITULARES  SER  RESPONSÁVEL POR QUALQUER RECLAMAÇÃO, #
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
# v1   - [01/09/2014]                                                          #
# - Primeiro release. Exibe informacoes ;                                      #
# v1.1 - [14/09/2014]                                                          #
# - Alteracao na exibicao do json para se adequar ao amchart;                  #
# v1.2 - [15/10/2014]                                                          #
# - Melhorias na execucao usando arquivo de lock;                              #
# v1.3 - [16/10/2014]                                                          #
# - Inclusao de timeout de 30 segundos na execucao do phantomjs;               #
# v1.4 - [21/10/2014]                                                          #
# - Cria e atualiza o arquivo json definido em JSONFILE;                       #
#                                                                              #
#------------------------------------------------------------------------------#

#[ Variaveis ]-----------------------------------------------------------------#

AWK=$(which awk)
SED=$(which sed)
DATE=$(which date)
GREP=$(which grep)
SCRIPTNAME=$(basename $0)
SCRIPTCONFFILE="phantomjs.conf"

# Arquivo de Lock
LOCKFILE=/tmp/${SCRIPTNAME}.lock

#[  Funcoes  ]-----------------------------------------------------------------#

trapfunction(){

	# Funcao chamada pelo 'trap', so remove o arquivo de lock
	# se o PID do script for igual ao pid no arquivo.

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

	# Funcao generica para exibir uma mensagem de erro e
	# retornar um codigo ao fim do script.

	# Pega a Mensagem e o Codigo de saida para o comando exit
	EXITCODE=$(echo $@ | awk '{print $NF}')
	EXITMESSAGE=$(echo $@ | awk '{ $NF = ""; print $0}')
	echo
	echo $EXITMESSAGE
	echo
	exit $EXITCODE
}

dataCollector(){

	# Funcao que coleta os dados de tempo de carregamento de urls usando
	# o PhantomJS, URL's que sao testadas estao relacionadas no arquivo
	# phantomjs.conf.

	if [ $TESTTYPE = "speed" ] ; then
		TESTTYPESCRIPT="$PHANTOMJSFILESDIR/loadspeed.js"
		TESTTYPECONF=""
	else
		exiterrorfunc "INFO: Funcao 'performance' ainda nao implementada 0"
		#TESTTYPESCRIPT="$PHANTOMJSFILESDIR/confess.js"
		#TESTTYPECONF="$PHANTOMJSFILESDIR/config.json"
	fi

	TESTTIMESTAMP=$($DATE +"%d-%m-%Y %H:%M")
	OUTPUTJSON=$OUTPUTJSON"{\"date\": \"$TESTTIMESTAMP\", "
	ELEMENTCOUNT=${#URLARRAY[*]}
	for (( i=0 ; i < $ELEMENTCOUNT ; i++ )); do
		RESULT=$(timeout 30s $PHANTOMJSBIN $TESTTYPESCRIPT ${URLARRAY[$i]} $TESTTYPECONF | $GREP 'Loading' | $AWK '{print $3}')
		wait
		if [ -z $RESULT ] ; then
			RESULT="0"
		fi
		OUTPUTJSON=$OUTPUTJSON"\"${SITENAMESARRAY[$i]}\": \"$RESULT\", "
	done
	OUTPUTJSON=${OUTPUTJSON%, }
	if [ -e $JSONFILE ] ; then
		$SED -i "s/\(}\) \(\]\)/\1,\n$OUTPUTJSON} \2/" $JSONFILE
	else
		echo "[ $OUTPUTJSON} ]" > $JSONFILE
	fi
	exit 0
}

#[ Carregando Arquivo de Conf ]------------------------------------------------#

if [ -e $SCRIPTCONFFILE ] ; then
	source $SCRIPTCONFFILE
else
	exiterrorfunc "ERRO: Arquivo phantomjs.conf nao encontrado 1"
fi

#[ testes, testes, testes ]--------------------------------------#

# Valida a existencia de um arquivo de lock
if [ -e $LOCKFILE ]; then
	exiterrorfunc "Script em execucao 1"
else
	echo "$$" > $LOCKFILE
fi

# valida se o binario do PhantomJS existe
[ $PHANTOMJSBIN ] || exiterrorfunc "ERRO: Binario 'phantomjs' nao encontrado 1"

# valida se foram passados parametros de linha de comando
[ $1 ] || exiterrorfunc "USAGE: $SCRIPTNAME [-s|-p] 1"

# valida se os parametros passados sao validos
[ `echo $1 | sed '/-[sp]/!d'` ] || exiterrorfunc "USAGE: $SCRIPTNAME [-s|-p] 1"

while getopts "sp" opts ; do
        case $opts in
                s) TESTTYPE="speed" ;;
                p) TESTTYPE="performance" ;;
        esac
done

dataCollector $TESTTYPE
