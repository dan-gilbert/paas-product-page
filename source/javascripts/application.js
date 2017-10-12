//= require header.js

jQuery(function($){
    $(".request-trial-form").change(function(e) {
        $(".request-trial-form").attr('action', e.target.value)
    });
});