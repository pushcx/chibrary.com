#!/usr/bin/ruby

# There are three kinds of jobs in the render queue:
# render_queue/slug                        - render the list description
# render_queue/slug/year/month             - render monthly thread list
# render_queue/slug/year/month/call_number - render/delete a thread

require 'rubygems'
require 'aws'
require 'haml'

class Renderer
  def get_job
    AWS::S3::Bucket.objects('listlibrary_cachedhash', :reload => true, :prefix => 'renderer_queue/', :max_keys => 1).first
  end

  def render_list slug
  end

  def render_month slug, year, month
  end

  def render_thread slug, year, month, calL_number
  end

  def delete_thread slug, year, month, calL_number
  end

  def run
    render_queue = CachedHash.new("render_queue")

    while job = get_job
      slug, year, month, call_number = job.key.split('/')[1..-1]
      $stdout.puts "#{slug} #{year} #{month} #{call_number}"
      job.delete

      if call_number # render/delete a thread
        if AWS::S3::S3Object.exists? "list/#{slug}/thread/#{year}/#{month}/#{call_number}", "listlibrary_archive"
          render_thread slug, year, month, call_number
        else
          delete_thread slug, year, month, call_number
        end
        render_queue["#{slug}/#{year}/#{month}"] = ''
      elsif year and month # render monthly thread list
        render_month slug, year, month
        render_queue["#{slug}"] = ''
      else # render list info page
        render_list  slug
      end
    end
  end
end
