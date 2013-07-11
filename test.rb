require './email2db'

# db.email_collection.remove()
# db.email_collection.find()
init_mongo()
msg = {"seqno"=>4, "uid"=>13, "internaldate"=>"10-Jul-2013 17:35:05 +0000", "flags"=>[:Seen], "date"=>"Wed, 10 Jul 2013 10:35:05 -0700", "subject"=>"Re: hey this is the subject", "from"=>["emailsilo@gmail.com"], "to"=>["jkoomjian@gmail.com"], "cc"=>["koomjian@freeshell.org"], "bcc"=>nil, "in_reply_to"=>"<CALMuob2ePJLKCGDUZhKptJMfh8_3NCxAfnbvNrvsPmgPdouXXg@mail.gmail.com>", "message_id"=>"<CADe-OadonGk+LU2nvPwpPPdfnsbCyCu7xZMzgnefHfQQE-9pGA@mail.gmail.com>"}
insert_msg(msg)