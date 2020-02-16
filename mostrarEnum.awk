#!/bin/awk -f

BEGIN {
  nAtributos = 0
  nConstantes = 0
  atributosEnum[++nAtributos][1] = "name"
  atributosEnum[nAtributos][2] = "String"
  nomeDoEnum = "qualquer nome"
}

# Obtém o nome da enumerção.
/(public|private) \<enum\> / {
  nomeDoEnum = obtemNomeDoEnum($0)
}

# Obtém os parâmetros do construtor, mesmo se eles estiverem quebrados
# em diversas linhas.
$0 ~ nomeDoEnum "\\s*\\(", /{/ {
  nParams = obtemParametrosDaFuncao(parametros)
  for (i = 1; i <= nParams; i++) {
    atributosEnum[++nAtributos][1] = parametros[i][1]
    atributosEnum[nAtributos][2] = parametros[i][2]
  }
}

# Obtém o verdadeiro nome das colunas descritivas do enum.
$0 ~ nomeDoEnum "\\s*\\(", /}/ {
  if (match($0, "=")) {
    substituiParametroPorAtributo(atributosEnum)
  }
}

# Obtém as colunas do enum.
/^(\t|\s+)[A-Z]+[^a-z]/ {
  obtemElementosEnum($0, elementosDeCadaConstante)
  nConstantes++
  for (i in elementosDeCadaConstante) {
    tabelaEnum[nConstantes][i] = elementosDeCadaConstante[i]
  }
}

END {
  # Imprime o tipo de cada coluna
  for (i in atributosEnum) {
    printf "%s\t", atributosEnum[i][2] 
  }
  print ""
  # Imprime o nome de cada coluna
  for (i in atributosEnum) {
    printf "%s ", atributosEnum[i][1] 
  }
  print "\n======================================"
  imprimeEnum(tabelaEnum, atributosEnum, nConstantes, nAtributos)
}
