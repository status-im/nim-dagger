## Nim-Dagger
## Copyright (c) 2021 Status Research & Development GmbH
## Licensed under either of
##  * Apache License, version 2.0, ([LICENSE-APACHE](LICENSE-APACHE))
##  * MIT license ([LICENSE-MIT](LICENSE-MIT))
## at your option.
## This file may not be copied, modified, or distributed except according to
## those terms.

import std/sequtils
import chronos
import ../blocktype

export blocktype

type
  ChangeType* {.pure.} = enum
    Added, Removed

  BlockStoreChangeEvt* = object
    cids*: seq[Cid]
    kind*: ChangeType

  BlocksChangeHandler* = proc(evt: BlockStoreChangeEvt) {.gcsafe, closure.}

  BlockProvider* = ref object of RootObj

  BlockStore* = ref object of BlockProvider
    changeHandlers: array[ChangeType, seq[BlocksChangeHandler]]
    blockProviders: seq[BlockProvider]

method getBlocks*(b: BlockProvider, cid: seq[Cid]): Future[seq[Block]] {.base.} =
  ## Get a block from the stores
  ##

  doAssert(false, "Not implemented!")

proc addChangeHandler*(
  s: BlockStore,
  handler: BlocksChangeHandler,
  changeType: ChangeType) =
  s.changeHandlers[changeType].add(handler)

proc removeChangeHandler*(
  s: BlockStore,
  handler: BlocksChangeHandler,
  changeType: ChangeType) =
  s.changeHandlers[changeType].keepItIf( it != handler )

proc triggerChange(
  s: BlockStore,
  changeType: ChangeType,
  cids: seq[Cid]) =
  let evt = BlockStoreChangeEvt(
    kind: changeType,
    cids: cids,
  )

  for handler in s.changeHandlers[changeType]:
    handler(evt)

method hasBlock*(s: BlockStore, cid: Cid): bool {.base.} =
  ## check if the block exists in the blockstore
  ##

  return false

method putBlocks*(s: BlockStore, blocks: seq[Block]) {.base.} =
  ## Put a block to the blockstore
  ##

  s.triggerChange(ChangeType.Added, blocks.mapIt( it.cid ))

method delBlocks*(s: BlockStore, blocks: seq[Cid]) {.base.} =
  ## delete a block/s from the block store
  ##

  s.triggerChange(ChangeType.Removed, blocks)
