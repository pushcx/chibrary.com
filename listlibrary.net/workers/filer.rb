#!/usr/bin/ruby

require 'time'
require 'rubygems'
require 'aws/s3'
require 'aws.rb'

class Message
  attr_reader :message

  def initialize message
    @message = message
    @connection = AWS::S3::Base.establish_connection!(
      :access_key_id     => ACCESS_KEY_ID,
      :secret_access_key => SECRET_ACCESS_KEY
    )

    @headers = /(.*?)\n\r?\n/m.match(@message)[1]
    date_line = /^Date:\W(.*)$/.match(@headers)[1]
    @date = Time.rfc2822(date_line) rescue Time.parse(date_line)
  end

  def mailing_list
    # TODO better mailing list identification
    /^X-Mailing-List:\W(.*)/.match(@headers)[1].chomp
  end

  def year
    @date.year
  end

  def month
    @date.month
  end

  def message_id
    # TODO deal with missing message_ids
    /^Message-[Ii][dD]:\W?<?(.*)>?/.match(@headers)[1]
  end

  def filename
    sprintf("#{mailing_list}/#{year}/%02d/#{message_id}", month)
  end

  def store
    AWS::S3::S3Object.store(filename, message, 'listlibrary_storage')
    filename
  end
end

puts Message.new("Return-Path: <linux-kernel-owner+archive=40listlibrary.net-S1762716AbXFRKHQ@vger.kernel.org>\r\nX-Original-To: archive@listlibrary.net\r\nDelivered-To: m3497675@swarthymail-mx1.g.dreamhost.com\r\nReceived: from vger.kernel.org (vger.kernel.org [209.132.176.167])\r\n\tby swarthymail-mx1.g.dreamhost.com (Postfix) with ESMTP id 49496189F7F\r\n\tfor <archive@listlibrary.net>; Mon, 18 Jun 2007 03:07:38 -0700 (PDT)\r\nReceived: (majordomo@vger.kernel.org) by vger.kernel.org via listexpand\r\n\tid S1762716AbXFRKHQ (ORCPT <rfc822;archive@listlibrary.net>);\r\n\tMon, 18 Jun 2007 06:07:16 -0400\r\nReceived: (majordomo@vger.kernel.org) by vger.kernel.org id S1760332AbXFRJ7l\r\n\t(ORCPT <rfc822;linux-kernel-outgoing>);\r\n\tMon, 18 Jun 2007 05:59:41 -0400\r\nReceived: from netops-testserver-3-out.sgi.com ([192.48.171.28]:58649 \"EHLO\r\n\trelay.sgi.com\" rhost-flags-OK-OK-OK-FAIL) by vger.kernel.org\r\n\twith ESMTP id S1760097AbXFRJ7S (ORCPT\r\n\t<rfc822;linux-kernel@vger.kernel.org>);\r\n\tMon, 18 Jun 2007 05:59:18 -0400\r\nReceived: from schroedinger.engr.sgi.com (schroedinger.engr.sgi.com [150.166.1.51])\r\n\tby netops-testserver-3.corp.sgi.com (Postfix) with ESMTP id 4111290A6B;\r\n\tMon, 18 Jun 2007 02:59:18 -0700 (PDT)\r\nReceived: from clameter by schroedinger.engr.sgi.com with local (Exim 3.36 #1 (Debian))\r\n\tid 1I0E10-0000IY-00; Mon, 18 Jun 2007 02:59:18 -0700\r\nMessage-Id: <20070618095917.943779191@sgi.com>\r\nReferences: <20070618095838.238615343@sgi.com>\r\nUser-Agent: quilt/0.46-1\r\nDate:\tMon, 18 Jun 2007 02:58:57 -0700\r\nFrom: clameter@sgi.com\r\nTo: akpm@linux-foundation.org\r\nCc: linux-kernel@vger.kernel.org, linux-mm@kvack.org,\r\n\tPekka Enberg <penberg@cs.helsinki.fi>\r\nCc: suresh.b.siddha@intel.com\r\nSubject: [patch 19/26] Slab defragmentation: Support reiserfs inode defragmentation\r\nContent-Disposition: inline; filename=slub_defrag_fs_reiser\r\nSender: linux-kernel-owner@vger.kernel.org\r\nPrecedence: bulk\r\nX-Mailing-List:\tlinux-kernel@vger.kernel.org\r\n\r\nAdd inode defrag support\r\n\r\nSigned-off-by: Christoph Lameter <clameter@sgi.com>\r\n\r\n---\r\n fs/reiserfs/super.c |   14 +++++++++++++-\r\n 1 file changed, 13 insertions(+), 1 deletion(-)\r\n\r\nIndex: slub/fs/reiserfs/super.c\r\n===================================================================\r\n--- slub.orig/fs/reiserfs/super.c\t2007-06-07 14:09:36.000000000 -0700\r\n+++ slub/fs/reiserfs/super.c\t2007-06-07 14:30:49.000000000 -0700\r\n@@ -520,6 +520,17 @@ static void init_once(void *foo, struct \r\n #endif\r\n }\r\n \r\n+static void *reiserfs_get_inodes(struct kmem_cache *s, int nr, void **v)\r\n+{\r\n+\treturn fs_get_inodes(s, nr, v,\r\n+\t\t\toffsetof(struct reiserfs_inode_info, vfs_inode));\r\n+}\r\n+\r\n+struct kmem_cache_ops reiserfs_kmem_cache_ops = {\r\n+\t.get = reiserfs_get_inodes,\r\n+\t.kick = kick_inodes\r\n+};\r\n+\r\n static int init_inodecache(void)\r\n {\r\n \treiserfs_inode_cachep = kmem_cache_create(\"reiser_inode_cache\",\r\n@@ -527,7 +538,8 @@ static int init_inodecache(void)\r\n \t\t\t\t\t\t\t reiserfs_inode_info),\r\n \t\t\t\t\t\t  0, (SLAB_RECLAIM_ACCOUNT|\r\n \t\t\t\t\t\t\tSLAB_MEM_SPREAD),\r\n-\t\t\t\t\t\t  init_once, NULL);\r\n+\t\t\t\t\t\t  init_once,\r\n+\t\t\t\t\t\t  &reiserfs_kmem_cache_ops);\r\n \tif (reiserfs_inode_cachep == NULL)\r\n \t\treturn -ENOMEM;\r\n \treturn 0;\r\n\r\n-- \r\n-\r\nTo unsubscribe from this list: send the line \"unsubscribe linux-kernel\" in\r\nthe body of a message to majordomo@vger.kernel.org\r\nMore majordomo info at  http://vger.kernel.org/majordomo-info.html\r\nPlease read the FAQ at  http://www.tux.org/lkml/\r\n").filename
