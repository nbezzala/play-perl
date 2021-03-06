define ["underscore", "jquery", "models/shared-models", "models/quest", "views/proto/base", "text!templates/quest-add.html", "bootstrap", "jquery.autosize"], (_, $, sharedModels, QuestModel, Base, html) ->
    Base.extend
        template: _.template(html)
        events:
            "click .quest-add": "submit"
            "keyup [name=name]": "nameEdit"
            "keyup [name=tags]": "tagsEdit"
            "click .quest-add-realm button": ->
                @validate checkRealm: false

        initialize: ->
            _.bindAll this
            $("#modal-storage").append @$el
            @render()

        disable: ->
            @$(".quest-add").addClass "disabled"
            @enabled = false

        enable: ->
            @$(".quest-add").removeClass "disabled"
            @enabled = true
            @submitted = false

        validate: (options) ->
            if (not options or options.checkRealm isnt false) and not @getRealm()
                @disable()
                return
            @$(".quest-add-realm-reminder").hide()
            if @submitted or not @getName()
                @disable()
                return
            @enable()
            qt = @$(".quest-tags-edit")
            tagLine = @$("[name=tags]").val()
            if QuestModel::validateTagline(tagLine)
                qt.removeClass "error"
                qt.find("input").tooltip "hide"
            else
                unless qt.hasClass("error")
                    qt.addClass "error"
          
                    # .tooltip() loses focus for some reason, so we have to save it and restore
                    #
                    # Note that animation for this tooltip is disabled, to avoid race conditions.
                    # I'm not sure how to fix them...
                    # http://ricostacruz.com/backbone-patterns/#animation_buffer talks about animation buffers,
                    # but I don't know how to integrate it with bootstrap-tooltip.js code - it doesn't accept any "onShown" callback.
                    oldFocus = $(":focus")
                    qt.find("input").tooltip "show"
                    $(oldFocus).focus()
                @disable()

        nameEdit: (e) ->
            @validate()
            @optimizeNameFont()
            @checkEnter e

        tagsEdit: (e) ->
            @validate()
            @checkEnter e

        optimizeNameFont: ->
            input = @$(".quest-edit-name")
            testerId = "#quest-add-test-span"
            tester = $(testerId)
            unless tester.length
                tester = $("<span id=\"" + testerId + "\"></span>")
                tester.css "display", "none"
                tester.css "fontFamily", input.css("fontFamily")
                @$el.append tester
            tester.css "fontSize", input.css("fontSize")
            tester.css "lineHeight", input.css("lineHeight")
            tester.text input.val()
            if tester.width() > input.width()
                newFontSize = parseInt(input.css("fontSize")) - 1
                if newFontSize > 14
                    newFontSize += "px"
                    input.css "fontSize", newFontSize
                    input.css "lineHeight", newFontSize

        getName: ->
            @$("[name=name]").val()

        getDescription: ->
            @$("[name=description]").val()

        getTags: ->
            tagLine = @$("[name=tags]").val()
            QuestModel::tagline2tags tagLine

        getRealm: ->
            @$(".quest-add-realm .active").attr "data-realm-id"

        render: ->
            that = this
            unless sharedModels.realms.length
                sharedModels.realms.fetch().success ->
                    that.render()

                return
            defaultRealm = @options.realm
            unless defaultRealm
                userRealms = sharedModels.currentUser.get("realms")
                defaultRealm = userRealms[0]  if userRealms and userRealms.length is 1
            @$el.html $(@template(
                realms: sharedModels.realms.toJSON()
                defaultRealm: defaultRealm
            ))
            qe = @$(".quest-edit-name")
            @$(".modal").modal().on "shown", ->
                qe.focus()

            @$(".modal").modal().on "hidden", (e) ->
        
                # modal includes items with tooltip, which can fire "hidden" too,
                # and these events bubble up DOM tree, ending here
                return  unless $(e.target).hasClass("modal")
                that.remove()

            @$(".btn-group").button()
            @$(".icon-spinner").hide()
            @submitted = false
            @validate()
            @$(".quest-edit-description").autosize append: "\n"

        submit: ->
            return  unless @enabled
            model_params =
                name: @getName()
                realm: @getRealm()

            description = @getDescription()
            model_params.description = description  if description
            tags = @getTags()
            model_params.tags = tags  if tags
            model = new QuestModel()
            model.save model_params,
                success: @onSuccess

            ga "send", "event", "quest", "add"
            mixpanel.track "add quest"
            @submitted = true
            @$(".icon-spinner").show()
            @validate()

        checkEnter: (e) ->
            @submit()  if e.keyCode is 13

        onSuccess: (model) ->
            Backbone.trigger "pp:quest-add", model
            @$(".quest-add-modal").modal "hide"


