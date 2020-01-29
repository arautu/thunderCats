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
function nameOfClass(line) {
  for(i = 1; i <= NF; i++) {
    if (match($i, "class")) {
      return $(i + 1)
    }
  }
}

# === Início do Programa ===
BEGIN {

}

# Obtém o nome do pacote.
NR==1,/^\<package\>/ {
  package = nameOfPkg($2)
}

# Obtém o nome da classe.
NR==1, / class / && !/^\/.*/ {
  className = nameOfClass($0)
}

# Imprime tudo
{}1

END {
  print package"."className"="
}

