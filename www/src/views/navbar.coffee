define [
    "jquery", "backbone",
    "views/proto/common",
    "models/current-user", "models/shared-models",
    "views/user/current", "views/quest/add",
    "text!templates/navbar.html"
], ($, Backbone, Common, currentUserModel, sharedModels, CurrentUser, QuestAdd, html) ->
    class extends Common
        template: _.template(html)
        events:
            "click .quest-add-nav-button": ->
                new QuestAdd(realm: @options.realm)

        afterInitialize: ->
            @listenTo Backbone, "pp:quiet-url-update", ->
                @render()

            that = this
            $(window).on "scroll.navbar-sticked", ->
                if $(window).scrollTop() > 10
                    that.$el.find("nav").addClass "sticked"
                else
                    that.$el.find("nav").removeClass "sticked"

        # navbar usually don't get removed, but just to be safe...
        remove: ->
            $(window).off ".navbar-sticked"
            super

        serialize: ->
            params =
                realm: @getRealm()
                partial: @partial
                registered: currentUserModel.get("registered")
                currentUser: currentUserModel.get("login")

            params

        getRealm: ->
            return  unless @options.realm
            realm = sharedModels.realms.findWhere(id: @options.realm)
            throw "Oops"  unless realm
            realm.toJSON()

        render: ->

            # wait for realms data; copy-paste from views/quest/add
            unless sharedModels.realms.length
                that = this
                sharedModels.realms.fetch().success ->
                    that.render()

                return
            super

        afterRender: ->
            unless @currentUser
                @currentUser = new CurrentUser(model: currentUserModel)
                @currentUser.setElement @$el.find(".current-user-box")
            else
                @currentUser.setElement(@$el.find(".current-user-box")).render()
            @$el.find(".menu-item-" + @active).addClass "active"  if @active

        setActive: (selector) ->
            @active = selector # don't render - views/app will call render() itself soon


