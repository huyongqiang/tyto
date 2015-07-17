Task = require './task'

module.exports = Backbone.Marionette.CompositeView.extend
  tagName   : 'div'
  className : ->
    this.domAttributes.COLUMN_CLASS
  attributes: ->
    attr = {}
    attr[this.domAttributes.COLUMN_ATTR] = this.model.get 'id'
    attr
  template  : Tyto.TemplateStore.column
  childView : Task
  childViewContainer: ->
    this.domAttributes.CHILD_VIEW_CONTAINER_CLASS
  events    :
    'click @ui.deleteColumn': 'deleteColumn'
    'click @ui.addTask'     : 'addTask'
    'blur @ui.columnName'   : 'updateName'
  ui        :
    deleteColumn: '#delete-column'
    addTask      : '.add-task'
    columnName   : '#column-name'
    taskContainer: '.tyto-column__tasks'
    columnMenu   : '.tyto-column__menu'

  collectionEvents:
    'destroy': 'handleTaskRemoval'

  domAttributes:
    COLUMN_CLASS              : 'tyto-column'
    COLUMN_ATTR               : 'data-col-id'
    PARENT_CONTAINER_CLASS    : '.tyto-board__columns'
    CHILD_VIEW_CONTAINER_CLASS: '.tyto-column__tasks'
    BOARD_CLASS               : '.tyto-board'
    IS_BEING_ADDED_CLASS      : 'is-adding-column'
    TASK_ATTR                 : 'data-task-id'
    TASK_CLASS                : '.tyto-task'
    TASK_MOVER_CLASS          : '.tyto-task__mover'
    TASK_PLACEHOLDER_CLASS    : 'tyto-task__placeholder'

  handleTaskRemoval: (e) ->
    view = this
    attr = view.domAttributes
    list = Array.prototype.slice.call view.$el.find attr.TASK_CLASS
    Tyto.Utils.reorder view, list, attr.TASK_ATTR

  childViewOptions: ->
    board    : this.getOption 'board'
    column   : this

  initialize: ->
    view = this
    attr = view.domAttributes
    view.$el.on 'animationend webkitAnimationEnd oAnimationEnd', ->
      $(view).parents(attr.BOARD_CLASS).removeClass attr.IS_BEING_ADDED_CLASS

  onBeforeRender: ->
    this.collection.models = this.collection.sortBy 'ordinal'

  bindTasks: ->
    view = this
    attr = view.domAttributes
    view.ui.taskContainer.sortable
      connectWith: attr.CHILD_VIEW_CONTAINER_CLASS
      handle     : attr.TASK_MOVER_CLASS
      placeholder: attr.TASK_PLACEHOLDER_CLASS
      containment: view.domAttributes.PARENT_CONTAINER_CLASS
      stop       : (event, ui) ->
        model           = view.collection.get ui.item.attr(attr.TASK_ATTR)
        destinationView = view
        newColId        = $(ui.item).parents('[' + attr.COLUMN_ATTR + ']').attr(attr.COLUMN_ATTR)

        if newColId isnt model.get 'columnId'
          destination     = Tyto.Columns.get newColId
          destinationView = Tyto.BoardView.children.findByModel destination
          list            = destinationView.$el.find attr.TASK_CLASS
          model.save
            columnId: newColId
          view.collection.remove model
          destinationView.collection.add model
          Tyto.Utils.reorder destinationView, list, attr.TASK_ATTR
          destinationView.render()

        list        = view.$el.find attr.TASK_CLASS
        Tyto.Utils.reorder view, list, attr.TASK_ATTR
        view.render()

        ###
          Not the prettiest piece of update code here but in order for the column menu to rebind, having to invoke upgradeDom().

          NOTE:: For some reason grabbing the elements and doing upgradeElement/
          upgradeDom does not work.

          If this proves too much hassle, could add extra method to view that ensures that on click, the relevant material class is added to the menu content.
        ###
        componentHandler.upgradeDom()

    return


  ###
    TODO:::: GO from here downwards/
  ###

  onShow: ->
    view = this
    columns = $(view.domAttributes.PARENT_CONTAINER_CLASS)[0]
    if columns.scrollWidth > window.outerWidth
      columns.scrollLeft = columns.scrollWidth
    this.bindMenu()
    
  onRender: ->
    this.bindTasks()

  bindMenu: ->
    view = this
    id   = view.model.id
    menu = view.ui.columnMenu
    yap menu[0]
    componentHandler.upgradeElement menu[0], 'MaterialMenu'

  updateName: ->
    this.model.save
      title: this.ui.columnName.text().trim()

  addTask: ->

    columnView = this
    columnView.$el.addClass 'is--adding'
    this.collection.add Tyto.Tasks.create
      columnId: columnView.model.id
      boardId : columnView.options.board.id
      ordinal : columnView.collection.length + 1

  deleteColumn: ->
    if confirm 'are you sure????'
      # NOTE w/ a backend we wouldn't be doing the recursive destroy.
      while this.collection.length isnt 0
        this.collection.first().destroy()
      this.model.destroy()
