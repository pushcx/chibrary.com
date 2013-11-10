module FlagsHelper
  def flag_link message
    flag_path :_method => 'POST', :flag => {
      :slug        => message.slug,
      :year        => message.date.year,
      :month       => message.date.month,
      :call_number => message.call_number
    }
  end
end
