define ["underscore", "views/proto/common", "views/notify", "views/navbar", "text!templates/app.html"], (_, Common, Notify, Navbar, html) ->
    Common.extend
        template: _.template(html)
        realm_id: null
        subviews:
            ".navbar-subview": ->
                new Navbar(realm: @realm_id)

        afterInitialize: ->
      
            # configure tracking
            mixpanel.init @partial.settings.mixpanel_id,
                track_pageview: false

            # TODO - configure localhost for debugging?
            ga "create", @partial.settings.analytics, window.location.host  if @partial.settings.analytics

        notify: (type, message) ->
            @$(".app-view-notifies").html ""
            @$(".app-view-notifies").append new Notify(
                type: type
                message: message
            ).render().el

        setPageView: (page) ->
      
            # the explanation of this pattern can be found in this article: http://lostechies.com/derickbailey/2011/09/15/zombies-run-managing-page-transitions-in-backbone-apps/
            # (note that the article is dated - it's pre-0.9.2, Backbone didn't have .listenTo() back then
            @_page.remove()  if @_page # TODO - should we remove all subviews too?
            @_page = page
            @$(".app-view-container").append page.$el
            menuItem = _.result(page, "activeMenuItem") or "none"
            @subview(".navbar-subview").setActive menuItem
      
            # FIXME - this leads to double-rendering navbar on the initial page load
            @updateRealm()

        updateRealm: ->
            realm = ((if @_page.realm then @_page.realm() else null))
            @realm_id = realm
            @subview(".navbar-subview").options.realm = @realm_id
            @subview(".navbar-subview").render()

        settingsDialog: ->
            @subview(".navbar-subview").currentUser.settingsDialog()


