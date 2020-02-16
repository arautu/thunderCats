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
  nPilhaFunc = 0
  nPilhaOver = 0
  inicioDoEscopo = 0
  fimDoEscopo = 0
  encontradoToString = 0
  atributosEnum[++nAtributos][1] = "name"
  atributosEnum[nAtributos][2] = "String"
  nomeDoEnum = "qualquer coisa"
}

# Obtém o nome da enumerção.
/(public|private) \<enum\>/ {
  nomeDoEnum = obtemNomeDoEnum($0)
}

# Obtém as colunas do enum.
/^(\t|\s+)[A-Z]+[^a-z]/ {
  obtemElementosEnum($0, elementosDeCadaConstante)
  nConstantes++
  for (i in elementosDeCadaConstante) {
    tabelaEnum[nConstantes][i] = elementosDeCadaConstante[i]
  }
  next
}

# Corresponde com os atributos do enum 
/private .*;/ {
  next
}

# Corresponde com o nome do enum.
# Obtém os parâmetros do construtor, mesmo se eles estiverem quebrados.
# em diversas linhas.
# Obtém o verdadeiro nome das colunas descritivas do enum.
# Imprime o enum refatorado.
# Imprime os atributos que ficaram no enum refatorado.
# Imprime o construtor, caso tenha ficado atributos no enum refatorado.
$0 ~ nomeDoEnum, /}/ {
  if (match($1, nomeDoEnum"\\(")) {
    while (!inicioDoEscopo) {
     nParams = obtemParametrosDaFuncao(parametros)
     for (i = 1; i <= nParams; i++) {
       atributosEnum[++nAtributos][1] = parametros[i][1]
       atributosEnum[nAtributos][2] = parametros[i][2]
     }
      inicioDoEscopo = match($NF, "{")
      getline
    }
    while (!fimDoEscopo) {
      if (match($0, "=")) {
        substituiParametroPorAtributo(atributosEnum)
      }
      if (match($0, "}")) {
        dividirListas(atributosEnum, listaDeExcluidos, colunasSelecionadas, 2)
        copiarLista(atributosEnum, atributosSemName, 2)
        delete atributosSemName[1]
      if (tamanhoDaLista(atributosEnum) == 1) {
        imprimeSomenteConstantes(tabelaEnum, nConstantes)
      }
      else {
        acrescentaAspas(tabelaEnum, atributosEnum)
        imprimeEnum(tabelaEnum, atributosEnum, nConstantes,
          tamanhoDaLista(atributosEnum))
        imprimeAtributos(atributosSemName)
        imprimeConstrutor(atributosSemName)
       }
       delete atributosSemName
      }
      fimDoEscopo = match($NF, "}")
      getline
    }
  }
}

# Corresponde com os métodos getters e is ou marcador com a tag @Override.
# Altera o escopo dos métodos que foram para o dicionário.
# Remove o método toString(). 
/@Override/ || /public .* (is|get)/, /}/ { 
  pilhaDaFuncao[++nPilhaFunc] = $0
  if (match($0, /public .* (is|get)/)) {
    nomeDoMetodo = $(NF - 1)
  }
  if (match($0, "return")) {
    nomeDoAtributo = encontraAtributoPeloMetodo($NF)
  }
  if (match($0, /public .* toString/)) {
    encontradoToString = 1
  }
  if (match($0, "}")) {
    achouExcluido = 0
    for (i in listaDeExcluidos) {
      if (nomeDoAtributo == listaDeExcluidos[i][1]) {
        print imprimeMetodoRefatorado(nomeDoMetodo, nomeDoAtributo)
        achouExcluido = 1
      }      
    }
    if (!achouExcluido && !encontradoToString) {
      for (i in pilhaDaFuncao) {
        print pilhaDaFuncao[i]
      }
    }
    nPilhaFunc = 0
    encontradoToString = 0
    delete pilhaDaFuncao
  }
  next
}

END {

}1
