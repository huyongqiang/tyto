Task = require './task'

module.exports = Backbone.Marionette.CompositeView.extend
  tagName   : 'div'
  className : 'column'
  attributes: ->
    id = this.model.get 'id'
    'data-col-id': id
  template  : Tyto.templateStore.column
  childView : Task
  childViewContainer: '.tasks'
  collection: ->
    debugger
  events    :
    'click @ui.deleteColumn': 'deleteColumn'
    'click @ui.addTask'     : 'addTask'
    'blur @ui.columnName'   : 'updateName'
  ui        :
    deleteColumn: '#delete-column'
    addTask     : '.add-task'
    columnName  : '#column-name'

  childViewOptions: ->
    boardView: this.getOption 'boardView'
    board : this.getOption 'board'
    column: this

  initialize: ->
    columnView = this

    this.model.on 'change:ordinal', (mod, opts) ->
      if !columnView.isDestroyed
        columnView.render()

    this.model.on 'change:title', (mod, opts) ->
      if !opts.ignore
        Tyto.UndoHandler.register
          action  : 'EDIT-COLUMN'
          model   : mod
          change  : mod.previousAttributes()
      columnView.render()

    this.collection.on 'add', (mod, col, opts) ->
      if !opts.ignore
        Tyto.UndoHandler.register
          action    : 'ADD-TASK'
          model     : mod
          collection: col

    this.collection.on 'remove', (mod, col, opts) ->
      if !opts.ignore
        Tyto.UndoHandler.register
          action    : 'REMOVE-TASK'
          model     : mod
          collection: col


  onBeforeRender: ->
    console.log 'rendering tasks'
    this.collection.models = this.collection.sortBy 'ordinal'

    newWidth = (100 / this.options.siblings.length) + '%'
    this.$el.css
      width: newWidth

  onRender: ->
    self        = this
    model       = `undefined`
    list        = `undefined`
    oldPos      = `undefined`
    this.$el.find('.tasks').sortable
      connectWith: '.tasks',
      placeholder: 'item-placeholder'
      containment: '.columns'
      opacity    : 0.8
      start      : (event, ui) ->
        model       = self.collection.get ui.item.attr('data-task-id')
        oldPos      = model.get 'ordinal'
      stop       : (event, ui) ->

        destinationView = self
        newColId = $(ui.item).parents('[data-col-id]').attr('data-col-id')

        if newColId isnt model.columnId
          destination     = Tyto.columnList.get newColId
          console.log 'ok here'
          destinationView = Tyto.boardView.children.findByModel destination
          list            = destinationView.$el.find '.tyto--task'

          model.set 'columnId', newColId
          model.save()

          self.collection.remove model
          destinationView.collection.add model


          Tyto.reorder destinationView, list, 'data-task-id'

          destinationView.render()

        # destinationView, colID


        # Want this part to be generic as possible.
        list        = self.$el.find '.tyto--task'
        Tyto.reorder self, list, 'data-task-id'
        self.render()

        Tyto.UndoHandler.register
          action  : 'MOVE-TASK'
          oldPos  : oldPos
          model   : model
          list    : list
          view    : self
          attr    : 'data-task-id'

    return

  updateName: ->
    col      = this.model
    oldTitle = col.get 'title'
    col.set 'title', @ui.columnName.text().trim()
    col.save()
    Tyto.UndoHandler.register
      action   : 'EDIT-COLUMN'
      model    : col
      property : 'title'
      val      : oldTitle
    return

  addTask: ->
    col = this
    newId   = _.uniqueId()
    newTask = new Tyto.Tasks.Task
      id     : newId
      columnId: col.model.id
      boardId: col.options.board.id
      ordinal: this.collection.length + 1

    # NOTE shouldn't be possible unless user accepts localStorage use.
    newTask.save()

    this.collection.add newTask

  deleteColumn: ->
    # Here need to iterate over the tasks and destroy them all.
    if confirm 'are you sure????'
      this.collection.forEach (task) ->
        task.destroy()
      this.model.destroy()
