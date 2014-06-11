from keyring import get_password

gmail_inbox_r2l = { 'INBOX' : 'INBOX' }
gmail_inbox_l2r = dict(reversed(x) for x in gmail_inbox_r2l.items())

gmail_others_r2l = { 
    '[Gmail]/All Mail' : 'Archive', '[Gmail]/Sent Mail' : 'Sent', 
    '[Gmail]/Drafts' : 'Drafts', '[Gmail]/Trash' : 'Trash', 
    '[Gmail]/Spam' : 'Spam' }
gmail_others_l2r = dict(reversed(x) for x in gmail_others_r2l.items())
