import std/macros

macro genNodeKinds() =
  result = newNimNode(nnkTypeSection)
  let typeDef = newNimNode(nnkTypeDef)
  typeDef.add(newNimNode(nnkPostfix).add(ident("*")).add(ident("MastNodeKind")))
  typeDef.add(newEmptyNode())
  let enumTy = newNimNode(nnkEnumTy)
  enumTy.add(newEmptyNode())
  for kind in NimNodeKind:
    enumTy.add ident(kind.repr[3 ..^ 1])
  typeDef.add(enumTy)
  result.add(typeDef)

genNodeKinds()

proc newNimNode*(kind: MastNodeKind): NimNode =
  newNimNode(NimNodeKind(kind.ord))

macro genSymKinds() =
  result = newNimNode(nnkTypeSection)
  let typeDef = newNimNode(nnkTypeDef)
  typeDef.add(newNimNode(nnkPostfix).add(ident("*")).add(ident("MastSymKind")))
  typeDef.add(newEmptyNode())
  let enumTy = newNimNode(nnkEnumTy)
  enumTy.add(newEmptyNode())
  for kind in NimSymKind:
    enumTy.add ident(kind.repr[3 ..^ 1])
  typeDef.add(enumTy)
  result.add(typeDef)

genSymKinds()

proc genSym*(kind: MastSymKind, name: string): NimNode =
  genSym(NimSymKind(kind.ord), name)
