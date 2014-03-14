POLL_FREQUENCY = 5000  # milliseconds


add_action_to_project_tiles = ->
    $('.project-tile .panel-body, .project-tile .panel-heading, .project-tile .panel-footer').click ->
      # Disabled for some reason I've forgotten. We should
      # re-try turbolinks on these. (RS)
      # Turbolinks.visit( $(@).parent().data('url') )  
      window.location = $(@).parent().data('url')  


set_icon = (project_id, is_working) ->
  button = $("#test-button-#{project_id}")
  spin   = 'fa-spin'
  
  if is_working == 'true'
    button.addClass(spin)
  else
    button.removeClass(spin)


set_progress_bar = (percent) ->
  console.debug("set_progress_bar #{percent}")
  bar       = $('#progress-bar')
  container = $('#progress-bar-container')
  
  if percent < 15  # Even if it's zero, we want to see some 
    percent = 15   # indication of activity
    
  bar.css('width', "#{percent}%")
  if percent == 100
    container.fadeOut(1300)
  else
    container.fadeIn(1000)


project_is_updated = (p_id, tested_at) ->
  server_time = tested_at
  client_time = $("#project-tile-#{p_id}").data('tested-at')
  client_time < server_time


update_project_tile = (p_id) ->
  console.debug("Updating project #{p_id}...")
  prefix   = $('#path-prefix').data('path-prefix')
  tile_url = prefix + '/ajax/' + "project_tile?project_id=#{p_id}"
  $.get(tile_url)
    .done( (html) ->
      $("#project-tile-#{p_id}").replaceWith(html)
      # Re-configure javascript events
      $("#project-tile-#{p_id} abbr.timeago").timeago();
      $("#project-tile-#{p_id}").hover ->   # TODO: do with CSS only
        $(@).toggleClass( 'project-tile-active' )
      add_action_to_project_tiles()
      )


do_poll = ->
  query  = $('#api-query').data('api-query')
  prefix = $('#path-prefix').data('path-prefix')

  # The page controls polling by setting or not setting
  # the api-query value.
  if query
    $.post(prefix + '/ajax/' + query)
      .done( (data) -> 
        # console.debug(JSON.stringify(data, undefined, 2))
        
        # Update activity indicators
        unless $("#server-status").hasClass('fa-signal')
          $("#server-status").removeClass().addClass("fa fa-fw fa-signal")
        set_progress_bar(data.percent_complete)
        set_icon(p, data.projects[p].queued) for p of data.projects

        # Update project tiles which have changed on the server
        for p_id, proj of data.projects
          if proj.queued == 'false' and project_is_updated(p_id, proj.tested_at)
            update_project_tile(p_id)

        add_action_to_project_tiles()
        )

      .fail( ->
        unless $("#server-status").hasClass('fa-ban')
          $("#server-status").removeClass().addClass("fa fa-fw fa-ban failed-icon")
        console.debug('fail'))
        
      .always( -> 
        window.think200_is_polling = true
        setTimeout(do_poll, POLL_FREQUENCY))

  else
    delete window.think200_is_polling


ready = ->
    add_action_to_project_tiles()

    $('.project-tile').hover ->
      $(@).toggleClass( 'project-tile-active' )

    $('.test-button').click (e) ->
      e.stopPropagation()
      $('body').focus()
      prefix  = $('#path-prefix').data('path-prefix')
      proj_id = $(@).data('project-id')
      url     = prefix + "/retest_project/#{proj_id}"
      set_icon(proj_id, 'true')
      set_progress_bar(0)
      $.post(url)

    $("abbr.timeago").timeago();

    # A simple way to set the focus in the right input.
    # Each page is responsible for adding the focus-here
    # class to the appropriate element.
    $('.focus-here').focus()

    if not window.think200_is_polling?
        do_poll()

    Prism.highlightElement( $('#rspec-export')[0] )


$(document).ready(ready)
$(document).on('page:load', ready)
Turbolinks.enableTransitionCache()
