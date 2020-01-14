#!/bin/sh
# Pega o arquivo original, faz uma cópia, convertendo-o
# para UTF-8.
fileName="src/$(echo $1 | rev | cut -f 1 -d / | rev)"
echo "Nome do arquivo=$fileName"
iconv -f iso-8859-1 -t utf8 $1 > $fileName

propertiesPath="/home/leandro/Sliic/git/sliic-erp/Sliic_ERP/Sliic_ERP_Beans/resources/i18n"
propertiesFile="messages-beans-rastreamento.properties"
tmpFile="lion.txt"

# Gera a variável pkgClassOrEnum com o nome do pacote
# e da classe no seguinte formato:
# pkgClassOrEnum=package.class

pkgClassOrEnum=$(
  sed -rn '
    s/\/\/.*//g
    1,/(\bclass\b|\benum\b)/ {
      /package/ {
        s/package (.*);.*/\1/
        h
      }
      /(public|private)(\s|\s\w+\s)class/ {
        s/.* class (\w+) .*/\1/
        G
        s/(.*)\n(.*)/\2.\1/p
      }
      /\benum\b/ {
        G
        s/(private|public) enum (\w+).*\n(.*)/\3.\2/p
      }
    }
  ' $fileName  
)
echo -e "package.class: $pkgClassOrEnum\n"

sed -rn '
  s/\/\/.*//g
  /(public|private) .* getDataAlteracaoAuditoria/d  
  /(public|private) .* getUsuarioAuditoria/d
  /(public|private) .* getId\b/d
  /@DisplayName/ {
    s/.*"(.*)".*/\1/
    h
  }
  1,/(\bclass\b|\benum\b)/ {
    /(\bclass\b|\benum\b)/ {
      G
      s/.*\n(.*)/'"$pkgClassOrEnum"'=\1/w '"$tmpFile"'
      b cleanHoldBuffer
    }
  }
  /(public|private) .* (is|get)\w/ {
    G
    s/ (is|get)./\L&\E/
    s/.* (is|get)(\w+)\(.*\n(.*)/'"$pkgClassOrEnum"'.\2=\3/w '"$tmpFile"'
    b cleanHoldBuffer
  }
  b
:cleanHoldBuffer
  s/.*//
  x
' $fileName

insere_arquivoFinal() {
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
      s/\/\/.*//g
      /package/,/\bclass\b/ {
        s/(public|private)(\s|\s\w+\s)class (\w+) .*/\3/p
      }
    ' $fileName
  )

  sed -ri '
    /@DisplayName/d
    /equals\(Object \w+\)/,/^$/ {
      H
      /^$/ {
        x
        /this.getId/!p
        /this.getId/c\
          public boolean equals(Object outro) {\
            return SliicUtil.objects.equals(this, ('"$NomeClasse"') outro, (e) -> e.getId());
          }
      }
    /int hashCode/,/return (this|id)/ {
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
