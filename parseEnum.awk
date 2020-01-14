#!/bin/awk -f 

# Retorna o nome do package
function nameOfPkg() {
  /^package/ 
    gsub(";.*", "",$2) 
    return $2
}

# Retorna o nome do enum.
function nameOfEnum(   i) {
  for (i = 1; i <= NF; ++i) {
    if ($i == "enum") {
      gsub("{", "", $(i+1))
      return $(i+1)
      break
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
    gsub(/(\t*|\s*|")/,"",enumConst[i])
  }
}
# Retorna o nome do atributo obtido do método get ou is.
function getAttributeByMethod(  method) {
  method = $3
  gsub(/(is|get|\(|\))/,"",method)
  return tolower(method)
}

# Retorna o nome do atributo.
function getAttribute() {
  sub(/(\t|;.*)/,"",$NF) 
  return $NF
}

# Retorna o nome do método
function getMethod() {
  gsub(/\(.+/, "", $3)
  return $3
}

# Obtém o valor de DisplayName
function getDisplayName(displayname,     ndisplayname) {

  ndisplayname = split($0,displayname,"\"")
  delete displayname[nsplit]
  getline

  if (/(public|private) enum /) {
    displayname[1] = nameOfEnum()
  }
  if (/public .* (is|get)/) {
    displayname[1] = getAttributeByMethod()
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
}

# Obtém o nome do pacote.
NR==1,/^package/ {
  package = nameOfPkg()
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
  enumeration = nameOfEnum()
}

# Ordena em array as contantes e suas respectivas descrições.
/^\t[A-Z]+[^a-z]/ {
  getConstEnum(description)
  nconstants++
  for (i in description) {
    descriptions[nconstants][i] = description[i]
  }
}

# Obtém os atributos
/private .*;/ {
  attributes[++nattributes] = getAttribute()
}

/public .* (is|get)/ {
  if (! /getNome/) {
    methods[++nmethods] = getMethod()
  }
}

END {
  # Imprime os métodos get.
  for (i in methods) {
    print "public MessageSourceResolvable " methods[i]"() {"
    printf "\tString code = this.getClass().getName() + \".\" + this.name() + \".%s\";\n", 
      attributes[i]
    print "\treturn new NextMessageSourceResolvable(code);"
    print "}"
  }
  
  # Imprime o vocabulário da enumeração.
  if (displayNames[1][1] == enumeration) {
    descricao=displayNames[1][2]
  }
  else {
    descricao=""
  }
  print package"."enumeration"="descricao

  # Imprime o vocabulário dos atributos.
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
  
  # Imprime o vocabulário das contantes do enum. 
  for (j=1; j <= nconstants; j++) {
    for (i in attributes) {
      print package"."enumeration"."descriptions[j][1]"."attributes[i]"="descriptions[j][i+1]
    }
  }
}
