#!/bin/awk -f

# Retorna o nome do package.
# Input: package -> Linha de texto contendo o package (ex. com.arauto.aff;).
# Output: O nome do package.
function obtemNomeDoPackage(package) {
  gsub(";.*", "",package)
  return package
}

# Retorna o nome da enumeração.
# Input: Linha de texto
# Output: Nome da enumeração
function obtemNomeDoEnum(frase,  i, lista) {
  split(frase, lista, /\s/)
  for (i in lista) {
    if (lista[i] == "enum") {
      sub("{", "", lista[i+1])
      return lista[i+1]
    }
  }
}

# Obtém o valor do @DisplayName.
# Input: frase -> linha contendo @DisplayName.
# Retorno: Valor do DisplayName.
function obtemDisplayName(frase,  displayName,nDisplayName) {
  nDisplayName = split(frase, displayName, "\"")
  return displayName[nDisplayName - 1]
}

# Dado um método getter ou is encontre o seu atributo correspondente
# Input: nomeDoMetodo -> texto que contém o nome do método, ex.
# this.nome_do_atributo;
# Retorno: Nome do atributo.
function encontraAtributoPeloMetodo(nomeDoMetodo) {
  sub(/^[[:alpha:]].*\./,"", nomeDoMetodo)
  sub(/(\(|;).*$/,"", nomeDoMetodo)
  return nomeDoMetodo
}

# Obtém os parâmetros de uma função
# Input: $0.
# Output: parâmetros -> Lista contendo 2 colunas: nome do parâmetro 
# e Tipo do parâmetro.
# Return: nParams -> Número de parâmetros.
function obtemParametrosDaFuncao(parametros,  nParams) {
  nParams = 0
  for (i = 1; i <= NF; i++) {
    if (match($i, /(,|\))/)) {
      parametros[++nParams][1] = $i
      parametros[nParams][2] = $(i - 1)
      sub(/(,|\))/, "", parametros[nParams][1])
    }
  }
  return nParams
}

# Substitui o nome do parâmetro do construtor pelo respectivo nome
# do atributo do enum.
# Input: atributosEnum -> Lista contendo o nome dos parâmetros do construtor, 
# na coluna 1 e o tipo na coluna 2. 
# Output: atributosEntum -> Lista contendo o atributo do enum correspondente ao
# parâmetro do construtor na linha 1 e o tipo na linha 2.
function substituiParametroPorAtributo(atributosEnum) {
  for (i in atributosEnum) {
    gsub(/(;|\s)/, "", $NF)
    if (match($NF, atributosEnum[i][1]) && RLENGTH == length($NF)) {
        atributosEnum[i][1] = $1
        sub("this.", "", atributosEnum[i][1])
    }
  }
}

# Retorna a constante enum de uma linha
# Input: frase -> Texto contendo a constante enum.
# Return: A constante enum.
function obtemConstanteEnum(frase, posFinal,   constanteEnum) {
  constanteEnum=substr(frase, 1, posFinal)
  gsub(/(\t|\s|\()+/, "", constanteEnum)
  return constanteEnum
}

# Retorna uma lista contendo as constantes e suas colunas descritivas.
# Input: frase -> Texto contendo a constante e suas respectivas colunas 
# descritivas.
# Output: lista -> Onde a primeira coluna é a constante do enum e as
# demais, são suas respectivas descrições.
function obtemElementosEnum(frase, lista,  array, i) {
  token = match(frase, /\(/)
  lista[1] = obtemConstanteEnum(frase, token)
  frase = substr(frase, token + 1)
  i = 1
  token = match(frase, /(,|;)/)
  while (token) {
    if (match(frase, /"/) == 1) {
      split(frase, array, "\"")
      lista[++i] = array[2]
      frase = null
      for (n in array) {
        frase = frase array[n + 2]
      }
      token = match(frase, ",")
    }
    else {
      lista[++i] = substr(frase, 1, token - 1)
    }
    gsub(/(^\s+|\)$)+/,"",lista[i])    
    frase = substr(frase, token + 1)
    token = match(frase, /(,|;)/)
  }
}

# Exclui as colunas de um array.
# Input: lista -> Lista ou Array que terá colunas removidas.
# Input: listaDeExclusao -> Lista com o número das colunas que serão removidas.
# Output: lista
function excluirColunas(lista, listaDeExclusao) {
  for (i in listaDeExclusao) {
    delete lista[listaDeExclusao[i]]
  }
}

# Cria 2 listas, sendo a primeira com as colunas que permanecerão no enum e 
# a segunda com as colunas excluídas.
# Input: lista -> Lista completa com todos elementos
# Input: numeroDosElementos -> Lista com o número dos elementos que serão
# separados.
# Input: colunas -> Se lista é multidimensional, informe o númer de colunas.
# Output: lista -> Lista sem os elementos descritos em numeroDosElementos.
# Output: sublista -> Lista com os elemento descritos em numeroDosElementos.
function dividirListas(lista, sublista, numeroDosElementos, colunas) {
  for (i in numeroDosElementos) {
    for (j = 1; j <= colunas; j++) {
      sublista[i][j] = lista[numeroDosElementos[i]][j]
      delete lista[numeroDosElementos[i]]
    }
  }
}

# Faz cópia de uma lista.
# Input: lista -> Lista a ser copiada.
# Input: colunas -> Número de colunas da lista.
# Output: copia -> Cópia da lista.
function copiarLista(lista, copia, colunas) {
  for (i in lista) {
    for (j = 1; j <= colunas; j++) {
      copia[i][j] = lista[i][j]
    }
  }
}

# Pega um texto de entrada separado por vírgula e transforma em uma lista, 
# removendo qualquer espaço entre eles.
# Input: variavel -> texto separado por vírgulas que será transformado em
# lista
# Output: lista
# Return: nlista -> Retorna o tamanho da lista.
function transformaVariavelEmLista(variavel, lista) {
  nlista = split(variavel, lista, ",")
  for (i in lista) {
    gsub(/\s/,"",lista[i])
  }
  return nlista
}

# Retorna o número de elementos de uma lista.
# Input: lista -> Nome da lista que será avaliada.
# Retorno: Número de elementos da lista
function tamanhoDaLista(lista) {
  for (i in lista) { }
    return i
}

# Imprime o método getter ou is, reescrito para usar o código de dicionário.
# Input: nomeDoMetodo
# Input: nomeDoAtributo
# Output: stdout -> Imprime o método
function imprimeMetodoRefatorado(nomeDoMetodo, nomeDoAtributo) {
  print "\npublic MessageSourceResolvable " nomeDoMetodo " {"
  printf "\tString code = this.getClass().getName() + \".\" + this.name()" \
    " + \".%s\";\n", nomeDoAtributo
  print "\treturn new NextMessageSourceResolvable(code);"
  print "}"
}

# Imprime a lista de atributos, ex: "private final String Descricao;".
# Input: listaDeAtributos -> Lista com duas colunas, sendo a primeira contendo
# o nome do atributo e a segunda o tipo do mesmo.
# Output: stdout
function imprimeAtributos (listaDeAtributos) {
  for (i in listaDeAtributos) {
      printf "private final %s %s;\n", listaDeAtributos[i][2], 
             listaDeAtributos[i][1]
  }
  printf "\n"
}

# Acrescenta aspas em colunas de tabela do tipo String.
function acrescentaAspas(tabela, lista) {
  for (i in tabela) {
    for (j in lista) {
      if (lista[j][2] == "String" && tabela[i][j] != "" && j != 1) {
        tabela[i][j] = "\"" tabela[i][j] "\""
      }
    }
  }
}

# Imprime as constantes e colunas do enum.
# Input: tabelaEnum -> Tabela contendo os elementos do enum.
# Input: atributosEnum -> Lista dos atributos correspondentes as
# colunas descritivas das constantes do enum.
# Input: ntabelaEnum -> Número de elementos de tabelaEnum.
# Input: nAtributos -> Número de elementos da tabela atributosEnum.
function imprimeEnum(tabelaEnum, atributosEnum, ntabelaEnum, nAtributos) {
  for (i in tabelaEnum) {
    for (j in atributosEnum) {
      if (j == 1) {
        printf " %s (", tabelaEnum[i][j]
      }
      else if (j == nAtributos && i != (ntabelaEnum)) {
        printf "%s),", tabelaEnum[i][j]
      }
      else if (j == nAtributos && i == (ntabelaEnum)) {
        printf "%s);", tabelaEnum[i][j]
      }
      else {
        printf "%s,\t", tabelaEnum[i][j]
      }
    }
    printf "\n"
  }
  printf "\n"
}

# Imprime somente as constantes do enum.
# Input: tabelaEnum -> Tabela contendo os elementos do enum.
# Input: ntabelaEnum -> Número de elementos de tabelaEnum.
function imprimeSomenteConstantes(tabelaEnum, ntabelaEnum) {
  for (i in tabelaEnum) {
    if (i != ntabelaEnum) {
      printf " %s,\n", tabelaEnum[i][1]
    }
    else {
      printf " %s;\n", tabelaEnum[i][1]
    }
  }
}

# Imprime o construtor com determinados parâmetros
# Input: parametros -> Lista com 2 colunas, sendo a primeira o nome do 
# parâmetro e a segunda o tipo do mesmo.
# Output: stdout
function imprimeConstrutor(parametros){
  printf "%s(", nomeDoEnum 
  for (i in parametros) {
      printf "final %s %s", parametros[i][2], parametros[i][1]
        if (i != tamanhoDaLista(parametros)) {
          printf ", "
        }
        else {
          printf ") {\n"
        }
    }
  for (i in parametros) {
    printf "this.%s = %s;\n", parametros[i][1], parametros[i][1]
  }
  printf "}\n"
}
