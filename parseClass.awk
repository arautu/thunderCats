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

function baseName(name) {
  gsub("get", "", name)
  gsub(/\(.*/, "", name)
  return tolower(substr(name, 1, 1)) substr(name, 2)
}

# === Início do Programa ===
BEGIN {
  nClass = 0
  nmethod = 0
  nline = 0
  change = 0
  braces = 0
}

# Obtém o nome do pacote.
NR==1,/^\<package\>/ {
  package = nameOfPkg($2)
}

# Obtém o nome da classe.
/\s\<class\>\s/ && !/^\/.*/ {
    if (nClass == 0) { 
      className[1] = nameOfClass()
      className[2] = displayName
      displayName = ""
      nClass++
    }
}

# Obtém os métodos.
/public .* (is|get)[[:alpha:]]/ &&
!/^\/.*/ && 
!/getDataAlteracaoAuditoria/ &&
!/getUsuarioAuditoria/ {
  methods[++nmethod][1] = nameOfMethod()
  methods[nmethod][2] = displayName
  displayName = ""
}
# Lê e remove @DisplayName
/^(\t|)@DisplayName/ {
  displayName = getDisplayName($0)
  next
}

/public .* equals/ {
  do {
    record[++nline] = $0
    if (match($0, "{")) {
      braces++
    }
    else if (match($0, "}")) {
      braces--
    }
    if (match($0, "getId")) {
      change = 1
    }
    getline
  } while (braces != 0) 

  if (change == 1) {
    change = 0
    print "\t@Override"
    print "\tpublic boolean equals(Object outro) {"
    print "\t\treturn SliicUtil.objects.equals(this, (Estado) outro, (e) -> e.getId());"
    print "\t}"
  } else {
    for (i in record) {
      print record[i++]
    }
  }
  nline = 0
  delete record
}1

END {
  print package "." className[1] "=" className[2]
  for (i in methods) {
    rawName = baseName(methods[i][1])
    print package "." className[1] "." rawName "=" methods[i][2]
  }
}

