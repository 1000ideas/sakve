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
    $('.fileupload').each(function() {
      LazyAdmin.fileupload_init(this);
    });

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
  },
  fileupload_init: function(element) {
    var value = $(element).data('value');
    $(element).wrap( $('<div>').addClass('button fileupload-button') );
    $(element).after( $('<span>').text( value ) );
    $(element).fileupload({
      dataType: 'json '
    });
  }
};


LazyAdmin = $.extend({}, LazyAdmin, LazyAdminExtension);
