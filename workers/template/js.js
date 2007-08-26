$(function() {
  $("blockquote").toggle(function() {
    // close up
    this.quote = $(this).html();
    $(this).html("---- click to show quote ----")
    $(this).toggleClass('closed');
  },function(){
    // open up
    $(this).html(this.quote)
    $(this).toggleClass('closed');
  }).each(function(){ $(this).click(); });
  if (location.hash) {
    $(location.hash).ScrollTo(0);
    $(location.hash).parent().find('blockquote').each(function(){ $(this).click(); });
  }
});
