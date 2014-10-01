$(function() {
  // month view: toggleable thread_lists
  $("li.thread").click(function(){
    $(this).toggleClass('closed');
    $(this).find('ol.thread_list').toggleClass('closed');
    $(this).find('.twiddler').toggleClass('open');
  }).dblclick(function() {
    if ($(this).is('.closed')) {
      $('li.thread').removeClass('closed').find('.twiddler').addClass('open');
      $('li.thread ol.thread_list').removeClass('closed');
    } else {
      $('li.thread').addClass('closed').find('.twiddler').removeClass('open');
      $('li.thread ol.thread_list').addClass('closed');
    }
  }).addClass('closed');
  $('ol.threads ol.thread_list').addClass('closed');

  // thread_list: show vertical line to pick out siblings
  $('ol.thread_list').mouseout(function(){
    $(this).css('background-position', '-1px 0px');
  }).mouseover(function(){
    var li = $(this), indent = li.css('padding-left');
    li.parent().css('background-position', indent + ' 0px');
  });

  // thread view: toggleable blockquotes
  $(".single-message, .thread").on('click', 'blockquote:not(.closed)', function() {
    // close up
    this.quote = $(this).html();
    $(this).html("---- click to show quote ----")
    $(this).toggleClass('closed');
  })
  .find('blockquote:not(.closed)').trigger('click');
  $(".single-message, .thread").on('click', 'blockquote.closed', function() {
    // open up
    $(this).html(this.quote)
    $(this).toggleClass('closed');
  })
  ;
  //.each(function(){ if (!$(this).is('.short')) $(this).click(); });
  // after page height changes, get back to named anchor
  if (location.hash) {
    window.scrollTo(0, $(location.hash)[0].offsetTop);
    $(location.hash).parent().find('blockquote.closed').click();
  }

  // thread view: hover over thread for parent/child links
  $(".message")
    .on('mouseenter', function(){ $(this).find(".more").show(); } )
    .on('mouseleave', function(){ $(this).find(".more").hide(); } );

  // thread view: keyboard shortcuts
  if ($('.thread').size()) {
    // find the top message displayed at least partially in the window
    var current_message = function() {
      var top = (document.all) ? document.body.scrollTop : window.pageYOffset;
      var match = null;
      $(".message").each(function(){
        if (this.offsetTop > top)
          return false;
        match = this;
      });
      if (match)
        return $(match);
    };
    $(document).keypress(function(e){
      if (e.altKey || e.ctrlKey || e.metaKey) return;
      switch(e.which) {
      case 106: // j, next message
        $(".more").hide();
        var current = current_message();
        if (current)
          var next = current.next();
        else
          var next = $(".message:first");
        next.find(".more").show();
        if (next.size() == 1)
          window.scrollTo(0, next[0].offsetTop);
        break;
      case 107: // k, previous message
        $(".more").hide();
        var current = current_message();
        if (current)
          var prev = current_message().prev();
        if (!current || prev.size() == 0)
          var prev = $("h1.subject");
        prev.find(".more").show();
        window.scrollTo(0, prev[0].offsetTop);
        break;
      case 105: // i, in-reply-to
        $(".more").hide();
        var current = current_message();
        if (current) {
          var a = current.find("a.in-reply-to")
          if (a.size() != 1)
            break;
          $(a.attr("href")).parent().find(".more").show();
          window.scrollTo(0, $(a.attr("href"))[0].offsetTop);
        }
        break;
      case 110: // n, next thread
        var n = $(".previous_next:first .next a");
        if (n.size() == 1)
          window.location = "http://chibrary.com" + n.attr("href");
        break;
      case 112: // p, previous thread
        var p = $(".previous_next:first .previous a");
        if (p.size() == 1)
          window.location = "http://chibrary.com" + p.attr("href");
        break;
      case 113: // q, toggle quotes in message
        var current = current_message();
        if (!current)
          current = $(".message:first");

        var b = current.find(".body blockquote:first");
        if (b.size() == 1 && b.is('.closed'))
          current.find(".body blockquote.closed").click();
        else
          current.find(".body blockquote:not(.closed)").click();
        break;
      case 81:  // Q, toggle all quotes
        var current = current_message();
        if (current)
          var b = current.find(".body blockquote:first");
        else
          var b = $(".body blockquote:first");
        if (b && b.size() == 1 && b.is('.closed'))
          $(".body blockquote.closed").click();
        else
          $(".body blockquote:not(.closed)").click();
        if (current)
          window.scrollTo(0, current[0].offsetTop);
        break;
      default:
        return true;
      }
      return false;
    });
  }

  // thread view: ajaxify the flag links
  $(".flag").css("display", "block").find("a").click(function(e){
    e.preventDefault();
    $(this).css("display", "none").after('<iframe src="' + $(this).attr("href") + '"></iframe>Thanks');
  });

  // show ads in production
  $.each(['google', 'live', 'msn', 'yahoo', 'localhost'], function(i, site) {
    var re = new RegExp ("http:\/\/[^\/]*" + site + ".*\/", "");
    if (re.exec(document.referrer)) {
      $(".panel").show();
    }
  });
});

