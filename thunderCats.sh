#!/bin/sh
# Pega o arquivo original, faz uma cópia, convertendo-o
# para UTF-8.
fileName="src/$(echo $1 | rev | cut -f 1 -d / | rev)"
echo "Nome do arquivo=$fileName"
iconv -f iso-8859-1 -t utf8 $1 > $fileName

propertiesPath="/home/leandro/Sliic/git/sliic-erp/Sliic_ERP/Sliic_ERP_Beans/resources/i18n"
propertiesFile="messages-beans-configuracao.properties"
tmpFile="lion.txt"

# Gera a variável packageClass com o nome do pacote
# e da classe no seguinte formato:
# packageClass=package.class
# Salva no Hold buffer a linha que contém o package.
# Anexa no Pattern buffer a linha do package com a linha
# que contém class.
# Formata a saída, removendo no fim o CR.
packageClass=$(
sed -rn '
  /package/h
  / class /G
  s/\s\n\s*/ /
  s/.* class (\w+) .* package (.*);/\2.\1/p 
  /class/q
' $fileName  
)
echo -e "package.class: $packageClass\n"

# Instrução SED para gerar a saída na seguinte forma:
# package.class.atribute=description.
# Inicialmente, remove da edição os atributos:
# dataAlteracaoAuditoria;
# usuarioAuditoria;
# id.
# Salva no Hold buffer a linha que contém @DisplayName.
# Altera a linha que contém o método get, passando a 
# primeira letra do atributo para minúsculo.
# Anexa a linha que está no Hold buffer (@DisplayName) com
# a linha que contém o método get.
# Substitui a quebra de linha por espaço.
# Cria a saída formatada.
sed -rn '
  /getDataAlteracaoAuditoria/d  
  /getUsuarioAuditoria/d
  /getId/d
  /@DisplayName/h
  s/get./\L&\E/
  /get/G
  /@DisplayName/!b noDisplayName
  s/\s\n\s*/ /
  s/.*get(.*)\(\) .*"(.*)".*/'"$packageClass"'.\1=\2/w '"$tmpFile"'
  s/.*is(.*)\(\) .*"(.*)".*/'"$packageClass"'.\1=\2/w '"$tmpFile"'
  x
  b
  :noDisplayName
  s/\s*public .* get(.*)\(.*/'"$packageClass"'.\1=/i w '"$tmpFile"'
  s/\s*public .* is(.*)\(.*/'"$packageClass"'.\1=/i w '"$tmpFile"'
' $fileName

insere_arquivoFinal() {
echo "$packageClass=" >> $propertiesPath/$propertiesFile
cat $tmpFile >> $propertiesPath/$propertiesFile
}

while true; do
  read -p "Inserir as propriedades em $propertiesFile? " yn
  case $yn in
    [SsYy]* ) insere_arquivoFinal; break;;
    [Nn]* ) exit;;
    * ) echo "Responda Sim ou Não.";;
  esac
done

edita_fonte() {
  NomeClasse=$(
    sed -rn '
      s/public class (\w+) .*/\1/p
      /class/q
  ' $fileName)
  
  sed -ri '
    /@DisplayName/d
    /equals\(Object arg0\)/,/return this.*/c\
      public boolean equals(Object outro) {\
              return SliicUtil.objects.equals(this, ('"$NomeClasse"') outro, (e) -> e.getId());
    /int hashCode/,/return (this|id)/{
      /if/,/return this/c\
              return id != null ? this.id.hashCode() : super.hashCode();
    }
  ' $fileName
  
} 

while true; do
  read -p "Editar o arquivo $fileName? " yn
  case $yn in
    [SsYy]* ) edita_fonte; break;;
    [Nn]* ) exit;;
    * ) echo "Responda Sim ou Não.";;
  esac
done

# Retorna o arquivo fonte para ISO-8859-1
iconv -f utf-8 -t iso-8859-1 $fileName > $1 
