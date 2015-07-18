Utils = (Utils, App, Backbone, Marionette) ->
  ###
    Syncs model 'ordinal' property to that of the DOM representation.

    NOTE :: This shouldn't be doing a loop through the collection using
    model.save. With a proper backend this could be avoided but on
    localStorage it will work with no real performance hit.
  ###
  Utils.reorder = (entity, list, attr) ->
    collection = entity.collection
    _.forEach list, (item, idx) ->
      id    = item.getAttribute attr
      model = collection.get id
      if model
        model.save
          ordinal: idx + 1

  Utils.load = (data, importing, wipe) ->
    boards  = []
    cols    = []
    tasks   = []
    altered = {}

    if importing
      delete data.tyto
      delete data['tyto--board']
      delete data['tyto--column']
      delete data['tyto--task']

    if wipe
      _.forOwn window.localStorage, (val, key) ->
        if key.indexOf('tyto') isnt -1
          window.localStorage.removeItem key

    _.forOwn data, (val, key) ->
      if wipe
        window.localStorage.setItem key, val
      if key.indexOf('tyto--board-') isnt -1
        if importing
          entity = JSON.parse val
          if Tyto.boardList.get(entity.id) isnt `undefined`
            saveId = entity.id
            delete entity.id
          altered[saveId] = Tyto.boardList.create(entity).id
        else
          boards.push JSON.parse val
      if key.indexOf('tyto--column-') isnt -1
        if importing
          entity = JSON.parse val
          if altered[entity.boardId]
            entity.boardId = altered[entity.boardId]
          if Tyto.columnList.get(entity.id) isnt `undefined`
            saveId = entity.id
            delete entity.id
          altered[saveId] = Tyto.columnList.create(entity).id
        else
          cols.push JSON.parse val
      if key.indexOf('tyto--task-') isnt -1
        if importing
          entity = JSON.parse val
          if altered[entity.boardId]
            entity.boardId = altered[entity.boardId]
          if altered[entity.columnId]
            entity.columnId = altered[entity.columnId]
          if Tyto.taskList.get(entity.id) isnt `undefined`
            saveId = entity.id
            delete entity.id
          altered[saveId] = Tyto.taskList.create(entity).id
        else
          tasks.push JSON.parse val

    if !importing
      Tyto.Boards.reset boards
      Tyto.Columns.reset cols
      Tyto.Tasks.reset tasks

module.exports = Utils
