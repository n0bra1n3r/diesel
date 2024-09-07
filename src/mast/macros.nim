import std/[enumerate, macros]

export macros except name, pragma, `pragma=`

proc `...`*(node: NimNode): seq[NimNode] =
  for child in node:
    result.add child

template `~>.`*(node: NimNode, field: untyped{nkIdent}): seq[NimNode] =
  var result = newSeq[NimNode]()
  for child in node:
    result.add child.field
  result

template `~>`*(
    node: NimNode, call: untyped{nkCall | nkCallStrLit | nkCommand}
): seq[NimNode] =
  var result = newSeq[NimNode]()
  for it {.inject.} in node:
    result.add call
  result

proc copyIdentDefs*(node: NimNode): NimNode =
  expectKind node:
    {
      nnkConstSection, nnkFormalParams, nnkGenericParams, nnkLetSection, nnkRecCase,
      nnkRecList, nnkVarSection,
    }

  result = node.kind.newTree()

  for identDef in node:
    if identDef.len > 3:
      let defType = identDef[^2]
      for ident in identDef[0 ..^ 3]:
        result.add newIdentDefs(ident, defType)
    else:
      result.add identDef

proc name*(node: NimNode): NimNode =
  expectKind node:
    RoutineNodes + {nnkConstDef, nnkExprColonExpr, nnkIdent, nnkIdentDefs, nnkTypeDef}
  case node.kind
  of nnkConstDef, nnkExprColonExpr, nnkIdentDefs, nnkTypeDef:
    result = node[0]
    if result.kind == nnkPragmaExpr:
      result = result[0]
    if result.kind == nnkPostfix:
      if result[1].kind == nnkAccQuoted:
        result = result[1][0]
      else:
        result = result[1]
    elif result.kind == nnkAccQuoted:
      result = result[0]
  of nnkIdent:
    result = node
  else:
    result = macros.name(node)

proc ofInherit*(node: NimNode): NimNode =
  expectKind node:
    nnkTypeDef
  expectKind node[2]:
    nnkObjectTy
  result = node[2][1]

proc `ofInherit=`*(node: NimNode, ofInheritNode: NimNode) =
  expectKind node:
    nnkTypeDef
  expectKind node[2]:
    nnkObjectTy
  expectKind ofInheritNode:
    nnkOfInherit
  node[2][1] = ofInheritNode

proc pragma*(node: NimNode): NimNode =
  expectKind node:
    RoutineNodes + {nnkConstDef, nnkIdentDefs, nnkTypeDef, nnkProcTy}
  case node.kind
  of nnkConstDef, nnkIdentDefs, nnkTypeDef:
    if node[0].kind == nnkPragmaExpr:
      result = node[0][1]
  else:
    result = macros.pragma(node)

proc `pragma=`*(node, pragma: NimNode) =
  expectKind node:
    RoutineNodes + {nnkConstDef, nnkIdentDefs, nnkTypeDef, nnkProcTy}
  expectKind pragma:
    nnkPragma
  case node.kind
  of nnkConstDef, nnkIdentDefs, nnkTypeDef:
    if node[0].kind == nnkPragmaExpr:
      node[0][1] = pragma
    else:
      node[0] = nnkPragmaExpr.newTree(node[0], pragma)
  else:
    macros.`pragma=`(node, pragma)

proc regenSyms*(node: NimNode): NimNode =
  let procNodes =
    {nnkConverterDef, nnkFuncDef, nnkIteratorDef, nnkMethodDef, nnkProcDef}
  let varNodes = {nnkConstSection, nnkFormalParams, nnkLetSection, nnkVarSection}
  expectKind node:
    procNodes + varNodes

  proc regenIdentDefs(kind: NimSymKind, identDefs: NimNode): NimNode =
    result = copyIdentDefs identDefs
    for i, def in enumerate result:
      if def.kind == nnkIdentDefs:
        result[i][0] = genSym(kind, def[0].repr)
      else:
        result[i] = def

  let kind =
    case node.kind
    of nnkConverterDef: nskConverter
    of nnkConstSection: nskConst
    of nnkFormalParams: nskParam
    of nnkFuncDef: nskFunc
    of nnkIteratorDef: nskIterator
    of nnkLetSection: nskLet
    of nnkMethodDef: nskMethod
    of nnkProcDef: nskProc
    of nnkVarSection: nskVar
    else: nskUnknown

  if node.kind in varNodes:
    result = regenIdentDefs(kind, node)
  elif node.kind in procNodes:
    result = copy node
    result.name = genSym(kind, result.name.repr)
    result.params = regenSyms(result.params)

proc shift*(node: NimNode): NimNode =
  expectMinLen node:
    1
  result = node[0]
  node.del 0
