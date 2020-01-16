#!/bin/awk -f 

# Retorna o nome do package
function nameOfPkg(package) {
  /^package/ 
    gsub(";.*", "",package) 
    return package
}

# Retorna o nome do enum.
function nameOfEnum(enumName,  i, array) {
  split(enumName, array, /\s/)
  for (i in array) {
    if (array[i] == "enum") {
      sub("{", "", array[i+1])
      return array[i+1]
    }
  }
}

# Retorna o array enumConst, onde a primeira coluna contém a constante Enum
# e nas demais, as descrições do enum.
function getConstEnum(enumConst,  splitConst, splitDesc) {

  split($0, splitConst, /(\(|\))/)
  split(splitConst[2], splitDesc, ",")
  
  enumConst[1] = splitConst[1]
  for (i in splitDesc) {
    enumConst[i+1] = splitDesc[i]
  }

  for (i in enumConst) {
    gsub(/(\t*|^\s*|")/,"",enumConst[i])
  }
}

# Retorna o nome do atributo obtido do método get ou is.
function getAttributeByMethod(method) {
  gsub(/(is|get|\(|\))/,"",method)
  return tolower(method)
}

# Retorna o nome do atributo.
function getAttribute(attr) {
  split(attr,array,/\s/)
  for (i in array) {
    if (match(array[i], /;$/)) {
      sub(";", "", array[i])
      return array[i]
    }
  }
}

# Retorna o nome do método
function getMethod() {
  method = $3
  gsub(/\(.+/, "", method)
  return method
}

# Obtém o valor de DisplayName
function getDisplayName(displayname,     ndisplayname) {

  ndisplayname = split($0,displayname,"\"")
  delete displayname[nsplit]
  getline

  if (/(public|private) enum /) {
    displayname[1] = nameOfEnum($0)
  }
  if (/public .* (is|get)/) {
    method = $3
    displayname[1] = getAttributeByMethod(method)
  }

  return ndisplayname
}

# -------- BEGIN -------------
BEGIN {
  i = 1
  nattributes = 0
  nconstants = 0
  nmethods = 0
  ndisplay = 0
  print "\n== enum de FILENAME ==\n"
}

# Obtém o nome do pacote.
NR==1,/^package/ {
  package = nameOfPkg($2)
}

/@DisplayName/ {
  getDisplayName(displayName) 
  ndisplay++
  for (i in displayName) {
    displayNames[ndisplay][i] = displayName[i]
  }
}

# Obtém o nome da enumerção.
/(public|private) enum / {
  enumeration = nameOfEnum($0)
  print $0"\n"
}

# Ordena em array as contantes e suas respectivas descrições.
/^\t[A-Z]+[^a-z]/ {
  getConstEnum(description)
  nconstants++
  for (i in description) {
    descriptions[nconstants][i] = description[i]
  }
  # Imprime as contantes
  gsub("\r","",$0)
  if (/,$/) {
    separador = ","
  }
  else {
    separador = ";\n"
  }
  print descriptions[nconstants][1] separador
}

# Obtém os atributos
/private .*;/ {
  attributes[++nattributes] = getAttribute($0)
}

# Imprime o método getNome()
/getNome/,/}/ {
  print $0
}

# Guarda em methods[] o nome do método (ex. methods[i] = getDescricao).
# O valor de nmethods é o tamanho de methods[].
# Reescreve os métodos getters levando em consideração o dicionário.
# O método getNome() é mantido inalterado.
/public .* (is|get)/ {
  methods[++nmethods] = getMethod()
  if (! /getNome/) {
    IGNORECASE = 1
    attr = null
    for (i in attributes) {
      if (match(methods[nmethods], attributes[i])) {
        attr = attributes[i]
        break
      }

    }
    IGNORECASE = 0
    if (attr == null) {
        printf "Erro: Não encontrado atributo correspondente ao método %s.\n", methods[nmethods]
        exit
    }
    print "\npublic MessageSourceResolvable " methods[nmethods]"() {"
    printf "\tString code = this.getClass().getName() + \".\" + this.name() + \".%s\";\n", 
      attr
    print "\treturn new NextMessageSourceResolvable(code);"
    print "}"
  }
}

# --- END ---
END {
  print "}" 
  print "\n== Vocabulário ==\n"
  # Imprime o código da enumeração.
  if (displayNames[1][1] == enumeration) {
    descricao=displayNames[1][2]
  }
  else {
    descricao=""
  }
  print package"."enumeration"="descricao

  # Imprime o código para getNome
  for (i in methods) {
    if (methods[i] == "getNome") {
      print package"."enumeration".nome="
    }
  }

  # Imprime o código dos atributos.
  for (i in attributes) {
    descricao = ""

    for (j=1; j <= ndisplay; j++) {

      if (attributes[i] == displayNames[j][1]) {
        descricao = displayNames[j][2]
          break
      }
    }
    print package"."enumeration"."attributes[i]"="descricao
  }

  
  # Imprime os códigos das contantes do enum. 
  for (j=1; j <= nconstants; j++) {
    for (i in attributes) {
      print package"."enumeration"."descriptions[j][1]"."attributes[i]"="descriptions[j][i+1]
    }
  }
}
