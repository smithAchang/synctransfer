#! /usr/bin/python3

import os
import sys
import smtplib
import json
from email.mime.text import MIMEText
from email.header import Header
import subprocess
import shlex

def issuper_oper(logline):
    #
    if logline.find("OK DOWNLOAD:") != -1:
       if logline.find("ftpsuper_") != -1:
           return "ftpsuper_"
    
    return ""

def readcfg(cfg_path):
    with open(cfg_path, "r" , encoding="utf-8") as f:
        cfg = json.load(f)
    
    return cfg

def getcfg_lastmodifytime(cfg_path):
    cfg_fd    = os.open(cfg_path, os.O_RDONLY)
    file_info = os.fstat(cfg_fd)
    return file_info.st_mtime

mail_infos = {
               'time':'unknown',
               'operator':'unknown',
               'access_ip':'unknown',
               'file':'unknown',
               'size':'unknown'
            }

mail_msg_template = """
<html>
 <body>
  <table align="center" border='1' cellpadding='1' cellspacing='0' width='90%'>
   <tbody>
     <tr><td align="center" bgcolor='#FF0000' colspan="2"><strong>Alarming</strong></td></tr>
     <tr><td width="10%" align="left">time</td><td align="center">{time}</td></tr>
     <tr><td width="10%" align="left">operator</td><td align="center">{operator}</td></tr>
     <tr><td width="10%" align="left">file</td><td align="center">{file}</td></tr>
     <tr><td width="10%" align="left">size</td><td align="center">{size}</td></tr>
     <tr><td width="10%" align="left">access_ip</td><td align="center">{access_ip}</td></tr>
   </tbody>
  </table>
 </body>
</html>
"""

Subject_template="{0} pull <<{1}>> alarm!"

# if hostname is not ftptransfer,neet change the hard-coding blow
HOST_NAME="ftptransfer"
MB_UNIT=(1024*1024)
SMTP_SERVER='10.1.2.3'
CFG_LAST_MODIFYTIME=0
NEWER_CFG_LAST_MODIFYTIME=0


if __name__ == '__main__':
    script_dir,filename    = os.path.split(os.path.realpath(sys.argv[0])) 
    pathtocfg              = script_dir + "/" + "cfg.json"
    cfg                    = readcfg(pathtocfg)
    CFG_LAST_MODIFYTIME    = getcfg_lastmodifytime(pathtocfg)

    # avoding duplicatly read older history when restart
    command                = "tail -F --lines=0 /var/log/vsftpd.log"
    args                   = shlex.split(command)
    child_p                = subprocess.Popen(args, shell=False,stdout=subprocess.PIPE, stderr=subprocess.STDOUT)

    while child_p.poll() is None:
        line = child_p.stdout.readline()

        try:
            line = line.decode()
            line = line.strip()
        except:
            print("readline exception,may occur disorder code! ftp client should use utf8 charset to access...")
            continue

        #print('Subprogram output: [{}]'.format(line))

        superlog_flag  = issuper_oper(line)
        if superlog_flag :
            NEWER_CFG_LAST_MODIFYTIME = getcfg_lastmodifytime(pathtocfg)

            if NEWER_CFG_LAST_MODIFYTIME > CFG_LAST_MODIFYTIME :
                cfg                  = readcfg(pathtocfg)
                CFG_LAST_MODIFYTIME  = NEWER_CFG_LAST_MODIFYTIME
                print("reload config again:{}".format(cfg))

            split_pos                = line.fine(HOST_NAME)
            mail_infos['time']       = line[0:split_pos]

            split_pos                = line.find(superlog_flag)
            next_split_pos           = line.find("]", split_pos)
            ftp_operator             = line[split_pos + len(superlog_flag):next_split_pos].strip()
            operator_details         = cfg['ftp_supers'][ftp_operator]

            if operator_detials is None:
                print("cannot get operator's detail info,please check!")
                continue


            mail_infos['operator']  = operator_details['name']
            split_pos               = line.find("Client",next_split_pos)
            line                    = line[split_pos + len("Client"):]
            downloadinfos           = line.split(",")
            mail_infos['access_ip'] = downloadinfos[0].strip().replace('"','')
            mail_infos['file']      = downloadinfos[1].strip().replace('"','')

            if not mail_infos['file'].startswith(operator_details['home']):
                mail_infos['file']  = operator_details['home'] + mail_infos['file']

            downloadinfos[2]        = downloadinfos[2].strip()
            split_pos               = downloadinfos[2].find("bytes")
            float_size              = float(downloadinfos[2][0:split_pos - 1])/MB_UNIT

            mail_infos['size']      = '%s , %.2f MBytes'%(downloadinfos[2],float_size)
            #print('keylog: {}'.format(str(mail_infos)))
            mail_content            = mail_msg_template.format(**mail_infos)
            #print('mail content: [{}]'.format(mail_content))

            sender                 = cfg['sender']
            receiver               = ";".join(cfg['receiver'])

            # list copy,must has all rept,include Cc&Bc
            receivers              = cfg['receiver'].copy()

            try:
                message            = MIMEText(mail_content, 'html','utf-8')

                message['From']    = sender
                message['To']      = receiver

                receiver_Cc        = cfg['receiver_Cc'].copy()
                receiver_Cc.extend(operator_details['receiver_Cc'])

                if not operator_details['mail'] in receiver_Cc :
                    receiver_Cc.append(operator_details['mail'])

                receiver_Cc       = list(set(receiver_Cc))
                receivers.extend(receiver_Cc)
                # remove the duplicated ele
                #print("original receivers:" + str(receivers))
                receivers         = list(set(receivers))

                message['Cc']     = ";".join(receiver_Cc)


                Subject_header_str = Subject_template.format(operator_details['name'], mail_infos['file'])
                #print('mail subject:{}'.format(Subject_header_str))

                message['Subject'] = Header(Subject_header_str,'utf-8')

                #print('before mail: {}'.format(message.as_string()))

                smtpObj            = smtplib.SMTP(SMTP_SERVER)
                smtpObj.sendmail(sender, receivers, message.as_string())
                smtpObj.close()

                print("send notice mail successfully...")
            except smtplib.SMTPException as err:
                print("Error:{}".format(err))
        else:
            continue




