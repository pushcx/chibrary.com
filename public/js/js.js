$(function() {
  // month view: toggleable thread_lists
  $("li.thread").click(function(){
    $(this).toggleClass('closed');
    $(this).find('ol.thread_list').toggleClass('closed');
  }).dblclick(function() {
    if ($(this).is('.closed')) {
      $('li.thread').removeClass('closed');
      $('li.thread ol.thread_list').removeClass('closed');
    } else {
      $('li.thread').addClass('closed');
      $('li.thread ol.thread_list').addClass('closed');
    }
  }).addClass('closed');
  $('ol.threads ol.thread_list').addClass('closed');

  // thread_list: show vertical line to pick out siblings
  $('ol.thread_list').mouseout(function(){
    $(this).css('background-position', '-1px 0px');
  });
  $('ol.thread_list li').mouseover(function(){
    var indent = $(this).attr('indent')
    if (typeof indent == 'undefined') {
      indent = $(this).find('span.indent').css('width')
      $(this).attr('indent', indent);
    }
    $(this).parent().css('background-position', indent + ' 0px');
  });

  // thread view: toggleable blockquotes
  $("div.body blockquote").toggle(function() {
    // close up
    this.quote = $(this).html();
    $(this).html("---- click to show quote ----")
    $(this).toggleClass('closed');
  },function(){
    // open up
    $(this).html(this.quote)
    $(this).toggleClass('closed');
  }).each(function(){ if (!$(this).is('.short')) $(this).click(); });
  // after page height changes, get back to named anchor
  if (location.hash) {
    $(location.hash).ScrollTo(0);
    $(location.hash).parent().find('blockquote.closed').each(function(){ $(this).click(); });
  }

  // thread view: hover over thread for parent/child links
  $("div.message").hover(
    function(){ $(this).find("div.more").show(); },
    function(){ $(this).find("div.more").hide(); }
  );

  // thread view: keyboard shortcuts
  // find the top message displayed at least partially in the window
  var current_message = function() {
    var top = (document.all) ? document.body.scrollTop : window.pageYOffset;
    var match = null;
    $("div.message").each(function(){
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
      $("div.more").hide(); 
      var current = current_message();
      if (current)
        var next = current.next();
      else
        var next = $("div.message:first");
      next.find("div.more").show();
      if (next.size() == 1)
        window.scrollTo(0, next[0].offsetTop);
      break;
    case 107: // k, previous message
      $("div.more").hide(); 
      var current = current_message();
      if (current)
        var prev = current_message().prev();
      if (!current || prev.size() == 0)
        var prev = $("h1.subject");
      prev.find("div.more").show();
      window.scrollTo(0, prev[0].offsetTop);
      break;
    case 105: // i, in-reply-to
      $("div.more").hide(); 
      var current = current_message();
      if (current) {
        var a = current.find("a.in-reply-to")
        if (a.size() != 1)
          break;
        $(a.attr("href")).parent().find("div.more").show();
        window.scrollTo(0, $(a.attr("href"))[0].offsetTop);
      }
      break;
    case 110: // n, next thread
      var n = $("div.previous_next:first .next a");
      if (n.size() == 1)
        window.location = "http://listlibrary.net" + n.attr("href");
      break;
    case 112: // p, previous thread
      var p = $("div.previous_next:first .previous a");
      if (p.size() == 1)
        window.location = "http://listlibrary.net" + p.attr("href");
      break;
    case 113: // q, toggle quotes in message
      var current = current_message();
      if (!current)
        current = $("div.message:first");

      var b = current.find("div.body blockquote:first");
      if (b.size() == 1 && b.is('.closed'))
        current.find("div.body blockquote.closed").click();
      else
        current.find("div.body blockquote:not(.closed)").click();
      break;
    case 81:  // Q, toggle all quotes
      var current = current_message();
      if (current)
        var b = current.find("div.body blockquote:first");
      else
        var b = $("div.body blockquote:first");
      if (b && b.size() == 1 && b.is('.closed'))
        $("div.body blockquote.closed").click();
      else
        $("div.body blockquote:not(.closed)").click();
      if (current)
        window.scrollTo(0, current[0].offsetTop);
      break;
    default:
      return true;
    }
    return false;
  });

  // thread view: ajaxify the flag links
  $("div.message div.header div.flag").css("display", "block").find("a").click(function(){
    console.log($(this).attr("href"));
    $(this).css("display", "none");
    $.get($(this).attr("href"));
    $(this).after("Thanks");
    return false;
  });
});
