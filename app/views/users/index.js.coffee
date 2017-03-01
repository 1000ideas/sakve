_content = $("<%=j render(@users) %>")
_more = $('.show-more')
$('.show-more').remove()
$('#users-list').append(_content)

<% unless @users.next_page.nil? %>
_more.find('a').attr('href', "<%=j url_for(params.merge(page: @users.next_page)) %>")
$('#users-list').append(_more)
<% end %>
