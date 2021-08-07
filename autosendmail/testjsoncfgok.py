#! /usr/bin/python3

import os
import sys
import json

def readcfg(cfg_path):
    with open(cfg_path, "r", encoding="utf-8") as f:
        cfg = json.load(f)

    return cfg

def getcfg_lastmodifytime(cfg_path):
    cfg_fd    = os.open(cfg_path,os.O_RDONLY)
    file_info = os.fstat(cfg_fd)
    
    return file_info.st_mtime


if __name__ == '__main__':
    script_dir,filename   = os.path.split(os.path.realpath(sys.argv[0]))
    pathtocfg             = script_dir + "/" + "cfg.json"
    cfg                   = readcfg(pathtocfg)
    CFG_LAST_MODIFYTIME   = getcfg_lastmodifytime(pathtocfg)
    print("cfgData:",cfg,"LAST_MODIFYTIME:",CFG_LAST_MODIFYTIME)

