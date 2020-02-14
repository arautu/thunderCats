#!/bin/awk -f

# Transforma a variável de ambiente em lista.
# Validação para retirar as colunas das contantes da lista de colunas a excluir
BEGIN {
  transformaVariavelEmLista(colunasEscolhidas, colunasSelecionadas)
  for (i in colunasSelecionadas) {
    if (colunasSelecionadas[i] == 1) {
      delete colunasSelecionadas[i]
    }
  }
  nAtributos = 0
  nConstantes = 0
}

# Obtém o nome do pacote.
/^\<package\>/ {
  nomeDoPackage = obtemNomeDoPackage($2)
  next
}

# Obtém o parâmetro de @DisplayName.
/@DisplayName/ {
  displayName = obtemDisplayName($0)
  next
}

# Obtém o nome do Enum.
/\s\<enum\>\s/ && !/^\/.*/ {
  nomeDoEnum[1] = obtemNomeDoEnum($0)
  nomeDoEnum[2] = displayName
  displayName = ""
}

# Obtém as constantes e colunas descritivas do enum.
/^(\t|\s+)[A-Z]+[^a-z]/ {
  obtemElementosEnum($0, elementosDeCadaConstante)
  nConstantes++
  for (i in elementosDeCadaConstante) {
    tabelaEnum[nConstantes][i] = elementosDeCadaConstante[i]
  }
  next
}

# Obtém os parâmetros associados com os métodos is e get.
# Salva em nomeDosAtributos na seguinte ordem:
# * coluna 1: Nome do atributo
# * coluna 2: Valor do displayName
/public .* (is|get)[[:alpha:]]/ && !/^\/.*/, /}/ {
  if (match($0, "return")) {
    nomeDosAtributos[++nAtributos][1] = encontraAtributoPeloMetodo($NF)
    nomeDosAtributos[nAtributos][2] = displayName
    displayName = ""
  }
  next
}

END {
# Imprime o código do enum.
  print nomeDoPackage"."nomeDoEnum[1]"="nomeDoEnum[2]
# Imprime os códigos dos métodos
  for (i in nomeDosAtributos) {
    if (nomeDosAtributos[i][1] != "name")
    print nomeDoPackage"."nomeDoEnum[1]"."nomeDosAtributos[i][1]"=" \
      nomeDosAtributos[i][2]
  }
# Imprime os códigos das constantes e suas colunas descritivas.
  for (i in tabelaEnum) {
    for (j in colunasSelecionadas) {
      print nomeDoPackage"."nomeDoEnum[1]"."tabelaEnum[i][1]"." \
        nomeDosAtributos[colunasSelecionadas[j]][1]"=" \
        tabelaEnum[i][colunasSelecionadas[j]]
    }
  }
}
