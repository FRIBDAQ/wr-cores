###############################################################################
## SPDX-FileCopyrightText: 2024 CERN (home.cern)
##
## SPDX-License-Identifier: LGPL-2.1-or-later
###############################################################################

###############################################################################
## Title      : Licence update script
## Project    : White Rabbit Switch
###############################################################################
## File       : licence_update.py 
## Author     : Quentin Genoud
## Company    : CERN BE-CEM-EDL
## Created    : 2024-11-18
## Last update: 2025-11-24 - Pietro King
## Platform   : PC
## Standard   : Python
###############################################################################
## Description:
## Script to add CERN SPDX header in different types of files
## It will automatically find the oldest year to put in the SPDX header
## and remove the previous header (under certain conditions)
## It will also create a CSV log file containing information about
## all the files parsed 
###############################################################################


import time
import signal
import sys
import argparse
import sys
import os
from os import walk
import glob
import re


##############
# PARAMETERS #
##############

# Name of CSV file which will contain the information about the parsed files
csv_file_name   = "info_licence.csv"

# Path to directory containing files to parse (./** : current directory, all subirs)
path            = "./**"

# Name of directories and / or files to be excluded from parsing
exclude_path    = [sys.argv[0], "ip_cores"]

# Extensions of files to be parsed
types           = ["py", "svh", "v", "vh", "sv", "tcl", "xdc", "vhd", "bmm", "ucf", "sh", "cheby", "sdc", "qsf", "do", "wb", "h", "cpp"]
# List of files in which to force add SPDX header even if there is no copyright
force_update    = ["Manifest.py"]
# Function used to force a files without copyright once they have been hand-checked
force_no_cp     = False

# Current date (used when adding header in file containing no date)
current_year    = 2025

# Number of '-' contained in the header delimiters (seems to be constant in wr-switch-hdl)
line_length     = 79

# Software licence string
licence_sw      = "LGPL-2.1-or-later"

# GW / HW licence string
licence_hdl     = "CERN-OHL-W-2.0+"

# Documentation licence string
licence_doc     = "CC-BY-SA-4.0+"


#############
# FUNCTIONS #
#############

def count_files(files, f_type):
    count = 0
    for f in files:
        if f.find(f_type) > -1 and f[-1] == f_type[-1]:
            count += 1
    return count

def get_extension(file): 
    ext = ""
    dot_nb = file.count(".")
    ext = file.split(".")[dot_nb]
    return ext

def get_extensions(file_list):
    #file_list = glob.glob(os.path.join(path, "*.*"), recursive=True)
    ext_list = []
    for f in file_list:
        ext = get_extension(f)
        not_listed = True
        for e in ext_list:
            if e == ext:
                not_listed = False
                break
        if not_listed == True:
            ext_list += [ext]
    return ext_list

def find_year(content):
    #valid_numbers = re.findall(r'\b(19|20)\d{4}\b', content)
    years = []
    for l in content.splitlines():
        if(l.find("Copyright") > -1 or
            l.find("copyright") > -1 or
            l.find("Created") > -1 or
            l.find("created") > -1):
            years = re.findall(r'(\b[2][0][0-9]{2}\b)', content)
            years += re.findall(r'(\b[1][9][0-9]{2})\b', content)
    y = []
    for y_s in years:
        y += [int(y_s)]
    if len(y) > 0:
        return min(y)
    else:
        return current_year

def is_copyright(content):
    for l in content.splitlines():
        if l.find("Copyright") > -1 or l.find("copyright") > -1:
            return True, l
    return False, ""

def is_copyright_cern(content):
    i = 0
    for l in content.splitlines():
        i += 1
        if l.find("Copyright") > -1 or l.find("copyright") > -1:
            if (l.find("CERN") > -1 or l.find("Cern") > -1 or l.find("cern") > -1):
                return True, l
            else:
                return False, l
    return False, ""

def is_copyright_spdx(cp_line):
    if cp_line.find("SPDX-FileCopyrightText") > -1:
        if (cp_line.find("CERN") > -1 or cp_line.find("Cern") > -1 or cp_line.find("cern") > -1):
            return True
        else:
            return False

def is_in_force_list(file, force_list):
    for f in force_list:
        #if(os.path.commonpath([file, f]) == f):
        if(file.find(f) > -1):
            return True
    return False

def find_files_with_exclusions(root_dir, exclude_dirs=None, pattern="**/*"):
    """
    Find all files in root_dir and subdirectories, excluding specified directories.

    :param root_dir: The root directory to start searching from.
    :param exclude_dirs: A list of directories to exclude from the search.
    :param pattern: The glob pattern for matching files (default is '**/*' to match all files).
    :return: List of file paths that match the pattern and are not in the excluded directories.
    """
    if exclude_dirs is None:
        exclude_dirs = []

    # Use glob to get all files in root_dir and subdirectories
    #all_files = glob.glob(os.path.join(root_dir, pattern), recursive=True)
    all_files = glob.glob(os.path.join(root_dir, "*."+pattern), recursive=True)

    #print(os.path.join(root_dir, pattern))

    # Filter out files that are in any of the excluded directories
    filtered_files = [
        file for file in all_files
        if not any(os.path.commonpath([file, exclude]) == exclude for exclude in exclude_dirs)
    ] 
    return filtered_files

def create_header(comment, licence, date, line_len):
    if(len(comment) == 2):
        com_char = comment[0]
    else:
        com_char = comment
        comment += comment
    
    delimiter = ""
    for i in range(0, line_len):
        delimiter += com_char

    header = "{}\n{} SPDX-FileCopyrightText: {} CERN (home.cern)\n{}\n{} SPDX-License-Identifier: {}\n{}\n" \
            .format(delimiter, comment, date, comment, comment, licence, delimiter)

    return header

def build_header(file, year):
    comment_v_sv_c = "//"
    comment_tex = "%"
    comment_sh_py_tcl = "#"
    header = ""

    ext = get_extension(file)
    if(ext == "vhd"): 
        header = create_header("--", licence_hdl, year, line_length)
    elif(ext == "v" or ext == "sv" or ext == "vh" or ext == "svh"):
        header = create_header("//", licence_hdl, year, line_length)
    elif(ext == "c" or ext == "h"):
        header = create_header("//", licence_sw, year, line_length)
    elif(ext == "sh" or ext == "py" or ext == "tcl"):
        header = create_header("#", licence_sw, year, line_length)
    elif(ext == "wb"):
        header = create_header("--", licence_sw+", "+licence_hdl, year, line_length)
    elif(ext == "cheby"):
        header = create_header("#", licence_sw+", "+licence_hdl, year, line_length)
    elif(ext == "sdc" or ext == "qsf"):
        header = create_header("#", licence_hdl, year, line_length)
    elif(ext == "do"):
        header = create_header("#", licence_sw, year, line_length)
    else:
        header = ""

    return header

def remove_old_header(content):
    i = 0
    begin_del_l = 0
    end_del_l = 0
    del_l = 0
    for l in content.splitlines():
        i += 1
        if (l.find("-----------------------------------------------") > -1) or (l.find("##############################################################################") > -1):
            del_l = i
            if(begin_del_l != 0 and  i != begin_del_l+2):
                end_del_l = del_l
                #print(f"Copyright delimiter lines: from {begin_del_l} to {end_del_l}")
                break
        if (l.find("Copyright") > -1 or l.find("copyright") > -1) and (l.find("Cern") > -1 or l.find("CERN") > -1 or l.find("cern") > -1):
            #print(f"found CERN copyright line {i}, saving start delimiter line {del_l}")
            begin_del_l = del_l
            del_l = 0
    updated = ""
    i = 0
    for l in content.splitlines():
        i += 1
        if(i < begin_del_l or i >= end_del_l):
            updated += l + "\n"
    return updated

def update_licence(fd, content):
    year = find_year(content)
    header = build_header(fd.name, year)
    content = remove_old_header(content)
    updated = ""
    first = True
    if content.splitlines()[0].find(header.splitlines()[0]) > -1:
        for l in content.splitlines():
            if first:
                first = False
            else:
                updated += l + "\n"
    else:
        updated = content
    updated = header + updated
    fd.truncate(0)
    fd.seek(0)
    fd.write(updated)
    fd.flush()
    fd.close()
    return not first


########
# MAIN #
########

if (__name__ == "__main__"):

    cwd = os.getcwd() 
    print("Looking for files in:", cwd)

    files = [] 
    total = 0
    cnt = []
    
    # create the csv file of the interesting files
    fd_lic = open(csv_file_name, "w+")
    fd_lic.write("File name;Copyright;Copyright CERN;Already CERN SPDX;Copyright added;Oldest year;Copyright line read\n")
    fd_lic.flush()

    # List all the files extensions you find (excluding submodules)
    tmp = find_files_with_exclusions(path, exclude_dirs=exclude_path, pattern="*")
    exts = get_extensions(tmp)
    print("Extension list: ")
    for e in exts:
        print("  - " + e)

    info = "File count per type:\n"
    for t in types:
        path_tmp = path + t
        #files.extend(glob.glob(path_tmp, recursive=True))
        f = find_files_with_exclusions(path, exclude_dirs=exclude_path, pattern=t)
        print("Counted {} files with extension .{}".format(len(f), t))
        files.extend(f)
        total += len(f)
        info += "  - .{:<4}: {} files\n".format(t, len(f))
    
    info += "Total number of files: {}".format(total)
    
    cp_added = False
    fline_rm_cnt = 0
    cp_added_cnt = 0
    cp_cern_cnt = 0
    cp_other_cnt = 0
    no_cp_cnt = 0
    cp_spdx_cnt = 0
    for f in files:
        for t in types:
            if get_extension(f) == t:
                fd = open(f, "r+")
                content = fd.read()
                year = find_year(content)
                cp_cern, cp_line = is_copyright_cern(content)
                force = is_in_force_list(f, force_update)
                cp_spdx = False
                cp_added = False
                if cp_cern or force:
                    cp_cern_cnt += 1
                    cp_spdx = is_copyright_spdx(cp_line)
                    if(not cp_spdx):
                        update_licence(fd, content)
                        cp_added_cnt += 1
                        cp_added = True
                    else:
                        cp_spdx_cnt += 1
                elif cp_cern == False and len(cp_line) > 0:
                    cp_other_cnt += 1
                elif force_no_cp == True:
                    update_licence(fd, content)
                    cp_added_cnt += 1
                    cp_added = True
                else:
                    no_cp_cnt += 1

                log_line = "{};{};{};{};{};{};{}\n".format(f,"YES" if len(cp_line) > 0 else "NO", 
                        "YES" if cp_cern else "NO", 
                        "YES" if cp_spdx else "NO", 
                        "YES" if cp_added else "NO",
                        year,
                        cp_line)
                fd_lic.write(log_line)
                fd_lic.flush()

    fd_lic.write("\n\nTotal number of files read;{}\n".format(total))
    fd_lic.write("Number of files with CERN copyright;{}\n".format(cp_cern_cnt))
    fd_lic.write("Number of files with other copyright;{}\n".format(cp_other_cnt))
    fd_lic.write("Number of files without copyright;{}\n".format(no_cp_cnt))
    fd_lic.write("Number of files with CERN SPDX copyright already present;{}\n".format(cp_spdx_cnt))
    fd_lic.write("Number of files updated (SPDX copyright added);{}\n".format(cp_added_cnt))
    fd_lic.write("Number of files NOT updated;{}\n".format(total - cp_added_cnt))
    
    print(info)
    print("\nNumber of files:")
    print("  - total parsed.................: {}".format(total))
    print("  - without copyright............: {}".format(no_cp_cnt))
    print("  - with other copyright.........: {}".format(cp_other_cnt))
    print("  - with CERN copyright..........: {}".format(cp_cern_cnt))
    print("  - with CERN SPDX copyright.....: {}".format(cp_spdx_cnt))
    print("  - updated with SPDX copyright..: {}".format(cp_added_cnt))
    print("  - NOT updated..................: {}".format(total - cp_added_cnt))

    print("Done!")
