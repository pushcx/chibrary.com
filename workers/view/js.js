$(function() {
  // month view: toggleable thread_lists
  $("ol.threads li.thread").click(function() {
    $(this).toggleClass('closed');
    $(this).find('ol.thread_list').toggleClass('closed');
  }).dblclick(function() {
    if ($(this).is('.closed')) {
      $('ol.threads li.thread').removeClass('closed');
      $('ol.threads li.thread ol.thread_list').removeClass('closed');
    } else {
      $('ol.threads li.thread').addClass('closed');
      $('ol.threads li.thread ol.thread_list').addClass('closed');
    }
  }).each(function(){ $(this).click(); });

  // thread_list
  $('ol.thread_list li a span.indent').each(function(){
    $(this).parent().parent().attr('indent', $(this).css('width'));
  });
  $('ol.thread_list li').mouseover(function(){
    $(this).parent().css('background-position', $(this).attr('indent') + ' 0px');
  });
  $('ol.thread_list').mouseout(function(){
    $(this).css('background-position', '-1px 0px');
  });

  // thread view: toggleable blockquotes
  $("div.message blockquote").toggle(function() {
    // close up
    this.quote = $(this).html();
    $(this).html("---- click to show quote ----")
    $(this).toggleClass('closed');
  },function(){
    // open up
    $(this).html(this.quote)
    $(this).toggleClass('closed');
  }).each(function(){ $(this).click(); });
  // after page height changes, get back to named anchor
  if (location.hash) {
    $(location.hash).ScrollTo(0);
    $(location.hash).parent().find('blockquote.closed').each(function(){ $(this).click(); });
  }
});
