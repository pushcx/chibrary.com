#!/usr/bin/ruby

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

  def run
    while job = get_job
      $stdout.puts job.key + " " + "*" * 50
      slug, year, month, call_number = job.key.split('/')[1..-1]
      job.delete

      # Jobs come in two ways: whole month or single thread
      # http://listlibrary.net/linux-kernel/2007/08
      # http://listlibrary.net/linux-kernel/2007/08/0asdf3f-
      threads = if call_number
        [call_number]
      else
        # list of all threads
      end

      threads.each do |thread|
        # if thread in s3
          render_thread slug, year, month, thread
        # else
          # delete it from site
      end

      render_month slug, year, month
      render_list  slug
    end
  end
end
