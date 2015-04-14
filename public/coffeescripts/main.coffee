# Funcion Main:
#     Coloca el resultado de llamar a parse en el OUTPUT.

main = ()->
  if INPUT.value is ""
    INPUT.value = "a = 1-2-3;"
  source = INPUT.value
  try
    result = JSON.stringify(parse(source), null, 2)
  catch result
    result = """<div class="error">#{result}</div>"""

  OUTPUT.innerHTML = result

clear = () ->
  OUTPUT.innerHTML = ""
  INPUT.value = ""

# Cuando ha cargado la página, asigna la funcion main () al onClick de los botones.
window.onload = ()->
  PARSE.onclick = main
  CLEAR.onclick = clear

Object.constructor::error = (message, t) ->
  t = t or this
  t.name = "SyntaxError"
  t.message = message
  throw treturn

RegExp::bexec = (str) ->
  i = @lastIndex
  m = @exec(str)
  return m  if m and m.index is i
  null

# Añade a la clase String el método "tokens".
# Este método convierte el string en un array de objetos tipo token (definidos más abajo).
String::tokens = ->
  from = undefined # The index of the start of the token.
  i = 0 # The index of the current character.
  n = undefined # The number value.
  m = undefined # Matching
  result = [] # An array to hold the results.
  tokens =
    WHITES: /\s+/g
    ID: /[a-zA-Z_]\w*/g
    NUM: /\b\d+(\.\d*)?([eE][+-]?\d+)?\b/g
    STRING: /('(\\.|[^'])*'|"(\\.|[^"])*")/g
    ONELINECOMMENT: /\/\/.*/g
    MULTIPLELINECOMMENT: /\/[*](.|\n)*?[*]\//g
    COMPARISONOPERATOR: /[<>=!]=|[<>]/g
    ONECHAROPERATORS: /([-+*\/=()&|;:,{}[\]])/g

  RESERVED_WORD =
    p:    "P"
    "if": "IF"
    then: "THEN"

  # Make a token object.
  # Aqui se define el objeto tipo token:
  make = (type, value) ->
    type: type
    value: value
    from: from
    to: i

  getTok = ->
    str = m[0]
    i += str.length # Warning! side effect on i
    str


  # Begin tokenization. If the source string is empty, return nothing.
  return  unless this

  # Loop through this text
  while i < @length
    for key, value of tokens
      value.lastIndex = i

    from = i

    # Ignore whitespace and comments
    if m = tokens.WHITES.bexec(this) or
           (m = tokens.ONELINECOMMENT.bexec(this)) or
           (m = tokens.MULTIPLELINECOMMENT.bexec(this))
      getTok()

    # name.
    else if m = tokens.ID.bexec(this)
      rw = RESERVED_WORD[m[0]]
      if rw
        result.push make(rw, getTok())
      else
        result.push make("ID", getTok())

    # number.
    else if m = tokens.NUM.bexec(this)
      n = +getTok()
      if isFinite(n)
        result.push make("NUM", n)
      else
        make("NUM", m[0]).error "Bad number"

    # string
    else if m = tokens.STRING.bexec(this)
      result.push make("STRING",
                        getTok().replace(/^["']|["']$/g, ""))

    # comparison operator
    else if m = tokens.COMPARISONOPERATOR.bexec(this)
      result.push make("COMPARISON", getTok())
    # single-character operator
    else if m = tokens.ONECHAROPERATORS.bexec(this)
      result.push make(m[0], getTok())
    else
      throw "Syntax error near '#{@substr(i)}'"
  result

# Metodo más importante.
#     Parse, recibe un parámetro: la cadena de entrada.
parse = (input) ->
  tokens = input.tokens()
  lookahead = tokens.shift() ## un "pop" por delante del array de tokens, es decir, recibe el primer token y lo elimina del array.

  # si el lookahead es de tipo t (el tipo pasado a la función match), avanza al siguiente token (y ya?). Si no, lanza un error.
  match = (t) ->
    if lookahead.type is t
      lookahead = tokens.shift()
      lookahead = null  if typeof lookahead is "undefined"
    else # Error. Throw exception
      throw "Syntax Error. Expected #{t} found '" +
            lookahead.value + "' near '" +
            input.substr(lookahead.from) + "'"
    return

  # Va rellenando un array con los resultados de "statement", separados por ";". Devuelve el array (o sólo el primer statement en caso de que sea sólo uno).
  statements = ->
    result = [statement()]
    while lookahead and lookahead.type is ";"
      match ";"
      if lookahead
        result.push statement()
    (if result.length is 1 then result[0] else result)

  # Devuelve 1 statement. Cada statement puede tener type, left, right, value.. (tanto left como right pueden ser expressions).
  statement = ->
    result = null
    if lookahead and lookahead.type is "ID"
      left =
        type: "ID"
        value: lookahead.value

      match "ID"
      match "="
      right = expression()
      result =
        type: "="
        left: left
        right: right
    else if lookahead and lookahead.type is "P"
      match "P"
      right = expression()
      result =
        type: "P"
        value: right
    else if lookahead and lookahead.type is "IF"
      match "IF"
      left = condition()
      match "THEN"
      right = statement()
      result =
        type: "IF"
        left: left
        right: right
    else # Error!
      throw "Syntax Error. Expected identifier but found " +
        (if lookahead then lookahead.value else "end of input") +
        " near '#{input.substr(lookahead.from)}'"
    result

  condition = ->
    left = expression()
    type = lookahead.value
    match "COMPARISON"
    right = expression()
    result =
      type: type
      left: left
      right: right
    result

  expression = ->
    result = expressionResta()
    if lookahead and lookahead.type is "+"
      match "+"
      exp = expression()
      result =
        type: "+"
        left: result
        right: exp
    result

  expressionResta = ->
    result = term()
    if lookahead and lookahead.type is "-"
      match "-"
      right = expressionResta()
      result =
        type: "-"
        left: result
        right: right
    result

  term = ->
    result = termDiv()
    if lookahead and lookahead.type is "*"
      match "*"
      right = term()
      result =
        type: "*"
        left: result
        right: right
    result

  termDiv = ->
    result = factor()
    if lookahead and lookahead.type is "/"
      match "/"
      right = termDiv()
      result =
        type: "/"
        left: result
        right: right
    result

  factor = ->
    result = null
    if lookahead.type is "NUM"
      result =
        type: "NUM"
        value: lookahead.value

      match "NUM"
    else if lookahead.type is "ID"
      result =
        type: "ID"
        value: lookahead.value

      match "ID"
    else if lookahead.type is "("
      match "("
      result = expression()
      match ")"
    else # Throw exception
      throw "Syntax Error. Expected number or identifier or '(' but found " +
        (if lookahead then lookahead.value else "end of input") +
        (if lookahead then " near '" + input.substr(lookahead.from) + "'" else ".")
    result

  tree = statements(input)
  if lookahead?
    throw "Syntax Error parsing statements. " +
      "Expected 'end of input' and found '" +
      input.substr(lookahead.from) + "'"
  tree
