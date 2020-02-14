#!/bin/sh

# Sair imediamente, caso aconteça algum erro
set -e

# Caminho e nome do arquivo dicionário 
propertiesPath="."
propertiesFile="messages-beans-rastreamento.properties"

# Copia o arquivo para a pasta src_utf8, convertendo-o para utf-8.
fileName="src_utf8/$(echo $1 | rev | cut -f 1 -d / | rev)"
echo -e "Nome do arquivo=$fileName"
iconv -f iso-8859-1 -t utf8 $1 > $fileName

# Imprime o enum, mostrando o tipo e o nome de cada coluna.
awk -f funcoesGeraisEnum.awk \
  -f mostrarEnum.awk $fileName

while true; do
  read -p "Escolhas as colunas que irão para o dicionário (ex: 2,3): " colunas
  case $colunas in
   "" ) echo "Nenhum valor digitado.";;
   [[:alpha:]] ) echo "Valores inválidos.";;
   * ) echo "Número da(s) coluna(s) escolhida(s): " $colunas; break;;
  esac
echo $colunas
done

# Gera os códigos para o dicionário.
awk -v colunasEscolhidas=$colunas \
  -f funcoesGeraisEnum.awk \
  -f criarDicionarioEnum.awk \
  $fileName >> $propertiesPath/$propertiesFile

# Refatora o enum, removendo métodos e atributos associados com as colunas
# retiradas.
awk -i inplace -v colunasEscolhidas=$colunas \
  -f funcoesGeraisEnum.awk \
  -f refatorarEnum.awk $fileName

# Converte para ISO-8859-1, copiando-o para a pasta de origem.
iconv -f utf-8 -t iso-8859-1 $fileName > $1
