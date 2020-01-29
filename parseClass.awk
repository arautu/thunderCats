#!/bin/awk -f

# Remove comentários e espaços no fim da instrução
# Entrada: String text;  // Texto qualquer
# Saída: String text;
function removeComments(line) {
  gsub(/\/.*/, "", line)
  gsub(/\s$/, "", line)
  return line
}

# Retorna o nome do package
function nameOfPkg(package) {
  /^package/ 
    gsub(";.*", "",package) 
    return package
}

# Retorna o nome da classe
function nameOfClass() {
  for(i = 1; i <= NF; i++) {
    if (match($i, "class")) {
      return $(i + 1)
    }
  }
}

# Obtém o nome do método
function nameOfMethod() {
   for(i = 1; i <= NF; i++) {
     if (match($i, /^(is|get)[[:alpha:]]/)) {
       methodName = $i
       sub("{", "", methodName)
       return methodName
     }
   }
}

function getDisplayName(line) {
  nsplit = split(line, asplit, "\"")
  return asplit[nsplit - 1]
}

function associateDisplaName(aDisplayName,  found) {
  aDisplayName[2] = getDisplayName($0) 
  found = 0
  do {
    getline
    if (/\s\<class\>\s/ && !/^\/.*/) {
      found = 1
      aDisplayName[1] = nameOfClass() 
    }
    else if (/\s(is|get)[[:alpha:]]+/) {
      found = 1
      aDisplayName[1] = nameOfMethod()
    }
  } while (!found)
}

# === Início do Programa ===
BEGIN {

}

# Obtém o nome do pacote.
NR==1,/^\<package\>/ {
  package = nameOfPkg($2)
}

# Obtém o nome da classe.
NR==1, /\s\<class\>\s/ && !/^\/.*/ {
  className = nameOfClass()
}

# Remove @DisplayName
/^(\t|)@DisplayName/ {
  associateDisplaName(aDisplayName)
  for (i in aDisplayName) {
    print "aDisplayName " aDisplayName[i]
  }
}

# Imprime tudo
{}1

END {
  print package"."className"="
}

