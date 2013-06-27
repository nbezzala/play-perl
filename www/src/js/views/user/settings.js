define([
    'underscore',
    'jquery',
    'views/proto/common',
    'settings',
    'text!templates/user-settings.html'
], function (_, $, Common, instanceSettings, html) {
    return Common.extend({
        template: _.template(html),

        events: {
           'click .resend-email-confirmation': 'resendEmailConfirmation',
           'keyup [name=email]': 'typing'
        },

        resendEmailConfirmation: function () {
            var btn = this.$('.resend-email-confirmation');
            if (btn.hasClass('disabled')) {
                return;
            }
            btn.addClass('disabled');

            $.post('/api/register/resend_email_confirmation', {})
            .done(function () {
                btn.text('Confirmation key sent');
            })
            .fail(function () {
                btn.text('Confirmation key resending failed');
            });
        },

        serialize: function () {
            var params = this.model.toJSON();
            params.hideEmailStatus = this.hideEmailStatus;
            return params;
        },

        start: function () {
            this.running = true;
            this.render();

            this.$('.email-status').show();
            this.$('input').prop('disabled', false);
            this.hideEmailStatus = false;
        },

        stop: function () {
            this.running = false;
            this.$('.email-status').hide();
            this.$('input').prop('disabled', true);
        },

        typing: function() {
            // We need both.
            // First line hides status immediately...
            this.$('.email-status').hide();
            // Second line guarantees that it doesn't show up for a moment when we call save() and re-render.
            this.hideEmailStatus = true;
        },

        // i.e., parse the DOM and return the model params
        deserialize: function () {
            var settings = {
                email: this.$('[name=email]').val(), // TODO - validate email
                notify_comments: this.$('[name=notify-comments]').is(':checked'),
                notify_likes: this.$('[name=notify-likes]').is(':checked'),
                notify_invites: this.$('[name=notify-invites]').is(':checked')
            };

            return settings;
        },

        save: function(cbOptions) {
            this.model.save(this.deserialize(), cbOptions);
        },
    });
});