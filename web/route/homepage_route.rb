get '/' do
  @lists = ListRepo.all

  haml :'generic/homepage.html'
end
