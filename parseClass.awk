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

# Retorna 1 se encontrar a chave "}" que fecha o escopo do método.
# Inputs:  line -> Linha de strings a ser testada.
#          braces -> Contador estático de chaves.
# Output: Retorna 1 ao encontrar a chave que fecha a função
#          e 0 caso contrário.
function closeBraceOfFunction(line,   out) {
  if (match(line, "{")) {
    braces++
  }
  else if (match(line, "}")) {
    braces--
  }
  (braces == 0) ?  out = 1 : out = 0
  return out
}

# Substitui o método equals(), dependendo do valor do parâmetro change.
# parâmetros: change -> Determina se a função vai substituir o método equals ou
# vai imprimir o que está no array record.
#             record -> Array com o método equals(). Normalmente é o método 
# existente.
# Retorno: Sem retorno.
function printEqualsMethod(change, record) {
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
  print "\n"
}

# === Início do Programa ===
BEGIN {
  nClass = 0
  nmethod = 0
  nline = 0
  change = 0
  braces = 0
  closeBrace = 0
}

# Salva em package o nome do pacote.
NR==1,/^\<package\>/ {
  package = nameOfPkg($2)
}

# Salva em clasName o nome da classe e seu respectivo valor de @DisplayName,
# caso tenha.
/\s\<class\>\s/ && !/^\/.*/ {
    if (nClass == 0) { 
      className[1] = nameOfClass()
      className[2] = displayName
      displayName = ""
      nClass++
    }
}

# Salva o nome do método no array methods e seu correpondente valor de 
# @DisplayName, caso tenha.
/public .* (is|get)[[:alpha:]]/ &&
!/^\/.*/ && 
!/getDataAlteracaoAuditoria/ &&
!/getUsuarioAuditoria/ {
  methods[++nmethod][1] = nameOfMethod()
  methods[nmethod][2] = displayName
  displayName = ""
}
# Obtém o parâmetro da tag @DisplayName e remove ela completamente.
/^(\t|)@DisplayName/ {
  displayName = getDisplayName($0)
  next
}

# Substitui o método equals() se ele possui a instrução getId() em seu escopo.
/public .* equals/ {
  while (!closeBrace) {
    record[++nline] = $0
    if (match($0, "getId")) {
      change = 1
   }
   closeBrace = closeBraceOfFunction($0)
   getline
  }
  printEqualsMethod(change, record)
  nline = 0
  delete record
  closeBrace = 0
}1

# End
END {
  print package "." className[1] "=" className[2]
  for (i in methods) {
    rawName = baseName(methods[i][1])
    print package "." className[1] "." rawName "=" methods[i][2]
  }
}

