var Helper = {
  split: function ( val ) {
    return val.split( /,\s*/ );
  },
  lastTerm: function ( term ) {
    return Helper.split( term ).pop();
  }
};

var LazyAdminExtension = {
  extension_setup: function() {
    $('.tags-autocomplete').autocomplete(this.tags_autocomplete_options);
  },
  tags_autocomplete_options: {
    source: function( request, response ) {
      $.getJSON( "/tags.json", {
        q: Helper.lastTerm( request.term )
      }, response );
    },
    search: function() {
      var term = Helper.lastTerm( this.value );
      if ( term.length < 1 ) {
        return false;
      }
    },
    focus: function() {
      return false;
    },
    select: function( event, ui ) {
      var terms = Helper.split( this.value );
      terms.pop();
      terms.push( ui.item.value );
      terms.push( "" );
      this.value = terms.join( ", " );
      return false;
    }
  }
};


LazyAdmin = $.extend({}, LazyAdmin, LazyAdminExtension);
