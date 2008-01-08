$(function() {
  // month view: toggleable thread_lists
  $("li.thread").click(function() {
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
    if (typeof indent == 'undefined')
      $(this).attr('indent', $(this).find('span.indent').css('width'));
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
});
